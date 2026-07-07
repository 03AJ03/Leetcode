WITH RECURSIVE words AS (
    SELECT
        content_id,
        content_text,
        1 AS pos,
        SUBSTRING_INDEX(content_text, ' ', 1) AS word,
        SUBSTRING(content_text,
                  LENGTH(SUBSTRING_INDEX(content_text, ' ', 1)) + 2) AS rest
    FROM user_content

    UNION ALL

    SELECT
        content_id,
        content_text,
        pos + 1,
        SUBSTRING_INDEX(rest, ' ', 1),
        SUBSTRING(rest,
                  LENGTH(SUBSTRING_INDEX(rest, ' ', 1)) + 2)
    FROM words
    WHERE rest <> ''
),

formatted AS (
    SELECT
        content_id,
        pos,
        CASE
            -- no hyphen
            WHEN word NOT LIKE '%-%' THEN
                CONCAT(
                    UPPER(LEFT(LOWER(word),1)),
                    SUBSTRING(LOWER(word),2)
                )

            -- starts or ends with '-' or contains '--'
            WHEN word LIKE '-%'
              OR word LIKE '%-'
              OR word LIKE '%--%' THEN
                CONCAT(
                    UPPER(LEFT(LOWER(word),1)),
                    SUBSTRING(LOWER(word),2)
                )

            -- proper hyphenated word
            ELSE
                CONCAT(
                    UPPER(LEFT(LOWER(SUBSTRING_INDEX(word,'-',1)),1)),
                    SUBSTRING(LOWER(SUBSTRING_INDEX(word,'-',1)),2),
                    '-',
                    UPPER(LEFT(LOWER(SUBSTRING_INDEX(word,'-',-1)),1)),
                    SUBSTRING(LOWER(SUBSTRING_INDEX(word,'-',-1)),2)
                )
        END AS word
    FROM words
)

SELECT
    u.content_id,
    u.content_text AS original_text,
    GROUP_CONCAT(f.word ORDER BY f.pos SEPARATOR ' ') AS converted_text
FROM user_content u
JOIN formatted f
ON u.content_id = f.content_id
GROUP BY u.content_id, u.content_text
ORDER BY u.content_id;
