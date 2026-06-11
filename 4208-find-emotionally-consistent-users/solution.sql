
WITH per_reaction AS (
    SELECT
        user_id,
        reaction,
        COUNT(*) AS reaction_count,
        SUM(COUNT(*)) OVER (PARTITION BY user_id) AS total_reactions
    FROM  reactions
    GROUP BY user_id, reaction
),

qualified AS (
    SELECT *
    FROM  per_reaction
    WHERE total_reactions >= 5
),

ranked AS (
    SELECT
        user_id,
        reaction AS dominant_reaction,
        reaction_count,
        total_reactions,
        RANK() OVER (
            PARTITION BY user_id
            ORDER BY reaction_count DESC
        )AS rnk
    FROM  qualified
)

SELECT
    user_id,
    dominant_reaction,
    ROUND(reaction_count * 1.0 / total_reactions, 2)    AS reaction_ratio
FROM  ranked
WHERE
    rnk = 1                                              
    AND reaction_count * 1.0 / total_reactions >= 0.60  
ORDER BY
    reaction_ratio DESC,
    user_id ASC;

