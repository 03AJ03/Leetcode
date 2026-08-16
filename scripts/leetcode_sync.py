import json
import os
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

import requests


GRAPHQL_URL = "https://leetcode.com/graphql"
SESSION = os.environ["LEETCODE_SESSION"]
CSRF_TOKEN = os.environ["LEETCODE_CSRF_TOKEN"]
FULL_SYNC = os.environ.get("FULL_SYNC", "false").lower() == "true"

HEADERS = {
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://leetcode.com/",
    "Origin": "https://leetcode.com",
    "x-csrftoken": CSRF_TOKEN,
}

COOKIES = {
    "LEETCODE_SESSION": SESSION,
    "csrftoken": CSRF_TOKEN,
}


def graphql(query, variables=None, operation_name=None):
    response = requests.post(
        GRAPHQL_URL,
        headers=HEADERS,
        cookies=COOKIES,
        json={
            "query": query,
            "variables": variables or {},
            "operationName": operation_name,
        },
        timeout=30,
    )
    response.raise_for_status()
    payload = response.json()
    if payload.get("errors"):
        raise RuntimeError(str(payload["errors"]))
    if "data" not in payload:
        raise RuntimeError(f"Unexpected LeetCode response: {payload}")
    return payload["data"]


def get_username():
    data = graphql(
        """
        query userStatus {
            userStatus { username isSignedIn }
        }
        """,
        operation_name="userStatus",
    )
    user = data["userStatus"]
    if not user["isSignedIn"]:
        raise RuntimeError("LeetCode session is not signed in.")
    return user["username"]


def get_recent_submissions(username, limit=100):
    data = graphql(
        """
        query recentAcSubmissions($username: String!, $limit: Int!) {
            recentAcSubmissionList(username: $username, limit: $limit) {
                id title titleSlug timestamp
            }
        }
        """,
        {"username": username, "limit": limit},
        "recentAcSubmissions",
    )
    return data.get("recentAcSubmissionList") or []


def get_solved_questions():
    data = graphql(
        """
        query userProgressQuestionList($filters: UserProgressQuestionListInput) {
            userProgressQuestionList(filters: $filters) {
                questions {
                    frontendId title titleSlug lastSubmittedAt
                    questionStatus lastResult
                }
            }
        }
        """,
        {"filters": {"questionStatus": "SOLVED", "skip": 0, "limit": 4000}},
        "userProgressQuestionList",
    )
    return data.get("userProgressQuestionList", {}).get("questions") or []


def get_latest_accepted_submission(title_slug):
    data = graphql(
        """
        query submissionList(
            $offset: Int!, $limit: Int!, $lastKey: String,
            $questionSlug: String!, $lang: Int, $status: Int
        ) {
            questionSubmissionList(
                offset: $offset limit: $limit lastKey: $lastKey
                questionSlug: $questionSlug lang: $lang status: $status
            ) {
                submissions {
                    id title titleSlug status statusDisplay lang langName timestamp
                }
            }
        }
        """,
        {
            "offset": 0,
            "limit": 1,
            "lastKey": None,
            "questionSlug": title_slug,
            "status": 10,
        },
        "submissionList",
    )
    submissions = data.get("questionSubmissionList", {}).get("submissions") or []
    return submissions[0] if submissions else None


def get_submission_details(submission_id):
    data = graphql(
        """
        query submissionDetails($submissionId: Int!) {
            submissionDetails(submissionId: $submissionId) {
                code timestamp statusCode
                lang { name verboseName }
                question { questionId title titleSlug }
            }
        }
        """,
        {"submissionId": int(submission_id)},
        "submissionDetails",
    )
    return data.get("submissionDetails")


def get_calendar_for_year(username, year):
    data = graphql(
        """
        query userProfileCalendar($username: String!, $year: Int) {
            matchedUser(username: $username) {
                userCalendar(year: $year) {
                    activeYears
                    totalActiveDays
                    submissionCalendar
                }
            }
        }
        """,
        {"username": username, "year": year},
        "userProfileCalendar",
    )

    calendar = data.get("matchedUser", {}).get("userCalendar") or {}
    raw = calendar.get("submissionCalendar") or "{}"

    if isinstance(raw, str):
        return json.loads(raw), calendar.get("activeYears") or []

    return raw, calendar.get("activeYears") or []


def get_all_calendars(username):
    # Ask LeetCode for the user's active years first, then fetch each year's calendar.
    calendars = {}
    _, active_years = get_calendar_for_year(username, None)

    if not active_years:
        active_years = [datetime.now(timezone.utc).year]

    for year in active_years:
        calendar, _ = get_calendar_for_year(username, int(year))
        calendars.update(calendar)

    return calendars


def clean_slug(slug):
    return re.sub(r"[^a-z0-9]+", "-", slug.lower()).strip("-")


def get_folder(question):
    try:
        number = f"{int(question['questionId']):04d}"
    except (ValueError, TypeError):
        number = str(question["questionId"])
    return f"{number}-{clean_slug(question['titleSlug'])}"


def get_extension(language):
    language = language.lower()
    extensions = {
        "python": ".py", "python3": ".py", "mysql": ".sql", "mssql": ".sql",
        "postgresql": ".sql", "oracle": ".sql", "sql": ".sql", "java": ".java",
        "c++": ".cpp", "cpp": ".cpp", "javascript": ".js", "typescript": ".ts",
        "c": ".c", "c#": ".cs", "csharp": ".cs", "go": ".go", "rust": ".rs",
        "kotlin": ".kt", "swift": ".swift", "ruby": ".rb", "php": ".php",
        "scala": ".scala",
    }
    return extensions.get(language, ".txt")


def parse_timestamp(value):
    if value is None:
        return None
    if isinstance(value, (int, float)) or str(value).isdigit():
        return datetime.fromtimestamp(float(value), tz=timezone.utc)
    value = str(value)
    if value.endswith("Z"):
        value = value[:-1] + "+00:00"
    dt = datetime.fromisoformat(value)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def git_date(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def has_marker(marker):
    result = subprocess.run(
        ["git", "log", "--all", "--format=%s", "--grep", marker],
        check=True,
        capture_output=True,
        text=True,
    )
    return bool(result.stdout.strip())


def commit_with_date(message, timestamp, allow_empty=False):
    env = os.environ.copy()
    env["GIT_AUTHOR_NAME"] = "03AJ03"
    env["GIT_AUTHOR_EMAIL"] = "203957546+03AJ03@users.noreply.github.com"
    env["GIT_COMMITTER_NAME"] = "03AJ03"
    env["GIT_COMMITTER_EMAIL"] = "203957546+03AJ03@users.noreply.github.com"
    env["GIT_AUTHOR_DATE"] = git_date(timestamp)
    env["GIT_COMMITTER_DATE"] = git_date(timestamp)

    command = ["git", "commit", "-m", message]
    if allow_empty:
        command.append("--allow-empty")
    subprocess.run(command, check=True, env=env)


def save_submission(details, submission_id, fallback_timestamp=None):
    if not details or details.get("statusCode") != 10:
        return False

    code = details.get("code")
    if not code:
        return False

    question = details["question"]
    language = details["lang"]["verboseName"]
    directory = Path(get_folder(question))
    directory.mkdir(parents=True, exist_ok=True)
    file_path = directory / f"solution{get_extension(language)}"

    timestamp = parse_timestamp(details.get("timestamp")) or parse_timestamp(fallback_timestamp)
    timestamp = timestamp or datetime.now(timezone.utc)

    marker = f"LeetCode submission: {submission_id}"
    if has_marker(marker):
        return False

    if file_path.exists():
        existing = file_path.read_text(encoding="utf-8")
        if existing.strip() == code.strip():
            # Preserve the exact LeetCode submission date in the contribution graph.
            commit_with_date(
                f"{marker} - {question['title']}", timestamp, allow_empty=True
            )
            print(f"CONTRIBUTION: {question['questionId']} - {question['title']} - {timestamp.date()}")
            return True

    file_path.write_text(code.rstrip() + "\n", encoding="utf-8")
    subprocess.run(["git", "add", str(file_path)], check=True)
    commit_with_date(f"{marker} - {question['title']}", timestamp)
    print(
        f"SYNCED: {question['questionId']} - {question['title']} "
        f"({language}) - {timestamp.isoformat()}"
    )
    return True


def sync_recent(username):
    submissions = get_recent_submissions(username, limit=100)
    print(f"Found {len(submissions)} recent accepted submissions.")
    for submission in submissions:
        try:
            details = get_submission_details(submission["id"])
            save_submission(details, submission["id"], submission.get("timestamp"))
        except Exception as exc:
            print(f"Failed: {submission.get('title')}: {exc}")


def sync_history():
    questions = get_solved_questions()
    print(f"Found {len(questions)} solved questions in LeetCode history.")
    for index, question in enumerate(questions, start=1):
        try:
            submission = get_latest_accepted_submission(question["titleSlug"])
            if not submission:
                continue
            details = get_submission_details(submission["id"])
            if details:
                save_submission(details, submission["id"], question.get("lastSubmittedAt"))
        except Exception as exc:
            print(f"[{index}/{len(questions)}] Failed: {question['title']}: {exc}")


def sync_heatmap(username):
    calendars = get_all_calendars(username)
    created = 0

    for unix_timestamp, count in calendars.items():
        if int(count) <= 0:
            continue

        day = datetime.fromtimestamp(int(unix_timestamp), tz=timezone.utc).date()
        marker = f"LeetCode calendar: {day.isoformat()}"

        if has_marker(marker):
            continue

        timestamp = datetime(day.year, day.month, day.day, 12, 0, 0, tzinfo=timezone.utc)
        commit_with_date(
            f"{marker} ({count} submissions)",
            timestamp,
            allow_empty=True,
        )
        created += 1

    print(f"Heatmap backfill: created {created} dated contribution commit(s).")


def push_commits():
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        check=True,
        capture_output=True,
        text=True,
    )

    if result.stdout.strip():
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(["git", "commit", "-m", "Sync LeetCode metadata"], check=True)

    ahead = subprocess.run(
        ["git", "rev-list", "--count", "origin/main..HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()

    if ahead != "0":
        subprocess.run(["git", "push", "origin", "main"], check=True)
        print(f"Pushed {ahead} commit(s) to GitHub.")
    else:
        print("Nothing new to push.")


def main():
    print("Checking LeetCode...")
    username = get_username()
    print(f"Logged in as: {username}")

    # Every run checks recent accepted submissions.
    sync_recent(username)

    # Full sync is only used when manually requested.
    if FULL_SYNC:
        print("FULL SYNC enabled: backfilling solved problems and heatmap.")
        sync_history()
        sync_heatmap(username)

    push_commits()
    print("Sync complete.")


if __name__ == "__main__":
    main()
