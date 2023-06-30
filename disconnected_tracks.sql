---- Here the example is using data from bern. To make it work for other regions, one needs to change the Code
---- in the marked regions to the wanted region.

WITH railway_ways AS(
    SELECT * FROM ways WHERE tags -> 'railway' = 'rail' or tags -> 'railway' = 'turntable' or tags ->  'railway' = 'bridge'
), end_nodes AS(
    SELECT
        node_id as id
    FROM (SELECT
        W1.nodes[1] as node_id
    FROM
        railway_ways W1
    UNION ALL
    SELECT
        W2.nodes[array_length(W2.nodes, 1)] as node_id
    FROM railway_ways W2) AS FOO
    
), single_nodes AS(
    SELECT
        end_nodes.id,
        COUNT(*) as count_nodes,
        ARRAY_AGG(railway_ways.id) as single_ways
    FROM
        end_nodes
        JOIN railway_ways ON
            end_nodes.id = ANY(railway_ways.nodes)
    
    GROUP BY end_nodes.id
    HAVING COUNT(*) = 1
), relevant_nodes AS (
    SELECT
        nodeees.*,
        count_nodes,
        single_ways
    FROM nodes nodeees
    INNER JOIN single_nodes
        ON single_nodes.id = nodeees.id
---- Change it from here
), bern AS (
    SELECT
        RM.relation_id as id,
        ST_BuildArea(ST_LineMerge(ST_Collect(W.linestring))) as collected
    FROM
        ways W
    JOIN relation_members RM ON
        W.id = RM.member_id AND RM.member_type = 'W' AND RM.relation_id = 1686344
    WHERE
        RM.member_role = 'outer'
    GROUP BY RM.relation_id
---- To here.
), stuff AS (
    SELECT 
        relevant_nodes.id,
        count_nodes,
        single_ways,
        relevant_nodes.geom
        FROM 
            relevant_nodes
        JOIN bern B ON True
        WHERE ST_Intersects(B.collected, relevant_nodes.geom)
)
SELECT 
    stuff.id
    FROM 
        stuff
        INNER JOIN railway_ways ON 
        ---- Choose your preferred dinstance here
        ST_Distance(ST_Transform(railway_ways.linestring, 3857), ST_Transform(stuff.geom, 3857)) < 3
    GROUP BY stuff.id
    HAVING COUNT(stuff.id) > 1
