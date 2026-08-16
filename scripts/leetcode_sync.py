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


class LeetCodeError(RuntimeError):
    pass


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
        raise LeetCodeError(str(payload["errors"]))

    if "data" not in payload:
        raise LeetCodeError(f"Unexpected LeetCode response: {payload}")

    return payload["data"]


def get_username():
    query = """
    query userStatus {
        userStatus {
            username
            isSignedIn
        }
    }
    """

    data = graphql(query, operation_name="userStatus")
    user = data["userStatus"]

    if not user["isSignedIn"]:
        raise LeetCodeError("LeetCode session is not signed in.")

    return user["username"]


def get_recent_submissions(username, limit=20):
    query = """
    query recentAcSubmissions($username: String!, $limit: Int!) {
        recentAcSubmissionList(username: $username, limit: $limit) {
            id
            title
            titleSlug
            timestamp
        }
    }
    """

    data = graphql(
        query,
        {"username": username, "limit": limit},
        "recentAcSubmissions",
    )

    return data.get("recentAcSubmissionList") or []


def get_solved_questions():
    query = """
    query userProgressQuestionList($filters: UserProgressQuestionListInput) {
        userProgressQuestionList(filters: $filters) {
            questions {
                frontendId
                title
                titleSlug
                lastSubmittedAt
                questionStatus
                lastResult
            }
        }
    }
    """

    variables = {
        "filters": {
            "questionStatus": "SOLVED",
            "skip": 0,
            "limit": 4000,
        }
    }

    data = graphql(
        query,
        variables,
        "userProgressQuestionList",
    )

    return data.get("userProgressQuestionList", {}).get("questions") or []


def get_latest_accepted_submission(title_slug):
    query = """
    query submissionList(
        $offset: Int!,
        $limit: Int!,
        $lastKey: String,
        $questionSlug: String!,
        $lang: Int,
        $status: Int
    ) {
        questionSubmissionList(
            offset: $offset
            limit: $limit
            lastKey: $lastKey
            questionSlug: $questionSlug
            lang: $lang
            status: $status
        ) {
            lastKey
            hasNext
            submissions {
                id
                title
                titleSlug
                status
                statusDisplay
                lang
                langName
                timestamp
            }
        }
    }
    """

    data = graphql(
        query,
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
    query = """
    query submissionDetails($submissionId: Int!) {
        submissionDetails(submissionId: $submissionId) {
            code
            timestamp
            statusCode
            lang {
                name
                verboseName
            }
            question {
                questionId
                title
                titleSlug
            }
        }
    }
    """

    data = graphql(
        query,
        {"submissionId": int(submission_id)},
        "submissionDetails",
    )

    return data.get("submissionDetails")


def clean_slug(slug):
    slug = slug.lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    return slug.strip("-")


def get_folder(question):
    try:
        number = f"{int(question['questionId']):04d}"
    except (ValueError, TypeError):
        number = str(question["questionId"])

    return f"{number}-{clean_slug(question['titleSlug'])}"


def get_extension(language):
    language = language.lower()

    extensions = {
        "python": ".py",
        "python3": ".py",
        "mysql": ".sql",
        "mssql": ".sql",
        "postgresql": ".sql",
        "oracle": ".sql",
        "sql": ".sql",
        "java": ".java",
        "c++": ".cpp",
        "cpp": ".cpp",
        "javascript": ".js",
        "typescript": ".ts",
        "c": ".c",
        "c#": ".cs",
        "csharp": ".cs",
        "go": ".go",
        "rust": ".rs",
        "kotlin": ".kt",
        "swift": ".swift",
        "ruby": ".rb",
        "php": ".php",
        "scala": ".scala",
    }

    return extensions.get(language, ".txt")


def parse_timestamp(value):
    if value is None:
        return None

    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value, tz=timezone.utc)

    value = str(value)

    if value.isdigit():
        return datetime.fromtimestamp(int(value), tz=timezone.utc)

    if value.endswith("Z"):
        value = value[:-1] + "+00:00"

    dt = datetime.fromisoformat(value)

    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)

    return dt.astimezone(timezone.utc)


def git_date(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def find_existing_solution(directory):
    if not directory.exists():
        return None

    for path in directory.glob("solution.*"):
        if path.is_file():
            return path

    return None


def commit_solution(path, title, timestamp):
    if not FULL_SYNC:
        return

    subprocess.run(
        ["git", "add", str(path)],
        check=True,
    )

    date = git_date(timestamp)

    env = os.environ.copy()
    env["GIT_AUTHOR_NAME"] = "03AJ03"
    env["GIT_AUTHOR_EMAIL"] = "203957546+03AJ03@users.noreply.github.com"
    env["GIT_COMMITTER_NAME"] = "03AJ03"
    env["GIT_COMMITTER_EMAIL"] = "203957546+03AJ03@users.noreply.github.com"
    env["GIT_AUTHOR_DATE"] = date
    env["GIT_COMMITTER_DATE"] = date

    subprocess.run(
        ["git", "commit", "-m", f"LeetCode: {title}"],
        check=True,
        env=env,
    )


def save_submission(details, fallback_timestamp=None):
    if not details:
        return False

    if details.get("statusCode") != 10:
        return False

    code = details.get("code")
    if not code:
        return False

    question = details["question"]
    language = details["lang"]["verboseName"]
    folder = get_folder(question)
    extension = get_extension(language)
    directory = Path(folder)
    directory.mkdir(parents=True, exist_ok=True)

    file_path = directory / f"solution{extension}"
    existing = find_existing_solution(directory)

    if existing:
        print(f"Already synced: {question['title']}")
        return False

    file_path.write_text(code.rstrip() + "\n", encoding="utf-8")

    timestamp = parse_timestamp(details.get("timestamp"))
    if timestamp is None:
        timestamp = parse_timestamp(fallback_timestamp)
    if timestamp is None:
        timestamp = datetime.now(timezone.utc)

    commit_solution(file_path, question["titleSlug"], timestamp)

    print(
        f"SYNCED: {question['questionId']} - "
        f"{question['title']} ({language}) - "
        f"{timestamp.isoformat()}"
    )

    return True


def sync_recent(username):
    submissions = get_recent_submissions(username)
    print(f"Found {len(submissions)} recent accepted submissions.")

    for submission in submissions:
        try:
            details = get_submission_details(submission["id"])
            save_submission(details, submission.get("timestamp"))
        except Exception as exc:
            print(f"Failed: {submission.get('title')}: {exc}")


def sync_history():
    questions = get_solved_questions()
    print(f"Found {len(questions)} solved questions in LeetCode history.")

    for index, question in enumerate(questions, start=1):
        try:
            submission = get_latest_accepted_submission(question["titleSlug"])

            if not submission:
                print(f"[{index}/{len(questions)}] No accepted submission: {question['title']}")
                continue

            details = get_submission_details(submission["id"])

            if details:
                save_submission(details, question.get("lastSubmittedAt"))

        except Exception as exc:
            print(
                f"[{index}/{len(questions)}] Failed: "
                f"{question['title']}: {exc}"
            )


def push_commits():
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        check=True,
        capture_output=True,
        text=True,
    )

    if result.stdout.strip():
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(
            ["git", "commit", "-m", "Sync LeetCode submissions"],
            check=True,
        )

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

    if FULL_SYNC:
        print("FULL SYNC enabled: backfilling solved problems.")
        sync_history()
    else:
        print("NORMAL SYNC: checking recent accepted submissions.")
        sync_recent(username)

    push_commits()
    print("Sync complete.")


if __name__ == "__main__":
    main()
