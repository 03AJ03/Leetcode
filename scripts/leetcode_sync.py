import os
import re
from pathlib import Path

import requests


GRAPHQL_URL = "https://leetcode.com/graphql"

SESSION = os.environ["LEETCODE_SESSION"]
CSRF_TOKEN = os.environ["LEETCODE_CSRF_TOKEN"]

HEADERS = {
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://leetcode.com/",
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

    data = response.json()

    if "errors" in data:
        raise Exception(data["errors"])

    return data["data"]


def get_username():
    query = """
    query userStatus {
        userStatus {
            username
            isSignedIn
        }
    }
    """

    data = graphql(
        query=query,
        operation_name="userStatus"
    )

    user = data["userStatus"]

    if not user["isSignedIn"]:
        raise Exception("LeetCode session is not signed in.")

    return user["username"]


def get_submissions(username):
    query = """
    query recentAcSubmissions(
        $username: String!,
        $limit: Int!
    ) {
        recentAcSubmissionList(
            username: $username,
            limit: $limit
        ) {
            id
            title
            titleSlug
            timestamp
        }
    }
    """

    data = graphql(
        query=query,
        variables={
            "username": username,
            "limit": 20
        },
        operation_name="recentAcSubmissions"
    )

    return data.get("recentAcSubmissionList") or []


def get_submission_details(submission_id):
    query = """
    query submissionDetails($submissionId: Int!) {
        submissionDetails(
            submissionId: $submissionId
        ) {
            code
            statusCode

            lang {
                name
                verboseName
            }

            question {
                questionId
                title
                titleSlug
                difficulty
            }
        }
    }
    """

    data = graphql(
        query=query,
        variables={
            "submissionId": int(submission_id)
        },
        operation_name="submissionDetails"
    )

    return data.get("submissionDetails")


def clean_slug(slug):
    slug = slug.lower()

    slug = re.sub(
        r"[^a-z0-9]+",
        "-",
        slug
    )

    return slug.strip("-")


def get_folder(question):
    number = int(question["questionId"])
    number = f"{number:04d}"

    slug = clean_slug(
        question["titleSlug"]
    )

    return f"{number}-{slug}"


def get_extension(language):
    language = language.lower()

    extensions = {
        "python": ".py",
        "python3": ".py",
        "mysql": ".sql",
        "sql": ".sql",
        "java": ".java",
        "c++": ".cpp",
        "cpp": ".cpp",
        "javascript": ".js",
        "typescript": ".ts",
        "c": ".c",
        "c#": ".cs",
        "go": ".go",
        "rust": ".rs",
        "kotlin": ".kt",
        "swift": ".swift",
    }

    return extensions.get(language, ".txt")


def save_submission(details):

    # LeetCode statusCode 10 = Accepted
    if details["statusCode"] != 10:
        return False

    code = details.get("code")

    if not code:
        return False

    question = details["question"]
    language = details["lang"]["verboseName"]

    folder = get_folder(question)
    extension = get_extension(language)

    directory = Path(folder)
    directory.mkdir(
        parents=True,
        exist_ok=True
    )

    file_path = directory / f"solution{extension}"

    # Don't rewrite identical code
    if file_path.exists():
        old_code = file_path.read_text(
            encoding="utf-8"
        )

        if old_code.strip() == code.strip():
            print(
                f"Already synced: {question['title']}"
            )
            return False

    file_path.write_text(
        code.rstrip() + "\n",
        encoding="utf-8"
    )

    print(
        f"SYNCED: "
        f"{question['questionId']} - "
        f"{question['title']} "
        f"({language})"
    )

    return True


def main():

    print("Checking LeetCode...")

    username = get_username()

    print(
        f"Logged in as: {username}"
    )

    submissions = get_submissions(username)

    print(
        f"Found {len(submissions)} "
        f"recent accepted submissions."
    )

    for submission in submissions:

        try:
            details = get_submission_details(
                submission["id"]
            )

            if details:
                save_submission(details)

        except Exception as e:
            print(
                f"Failed: "
                f"{submission.get('title')}"
            )
            print(e)

    print("Sync complete.")


if __name__ == "__main__":
    main()
