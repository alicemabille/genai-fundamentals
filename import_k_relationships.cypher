CALL apoc.periodic.iterate(
    'CALL apoc.load.json("file:///C:/Users/alice/.Neo4jDesktop2/Data/dbmss/dbms-190679c2-4330-49a1-8984-b6f3c9a02da5/import/merged_relationships.json")
     YIELD value
     UNWIND value.relationships AS r
     RETURN r',
    '
    MATCH (source:Knowledge {id: r.source})
    MATCH (target:Knowledge {id: r.target})
    CALL apoc.merge.relationship(source, r.type, {}, {comment: r.comment}, target)
    YIELD rel
    RETURN rel',
    {batchSize: 10000, parallel: false}
)
YIELD batches, total, updateStatistics
RETURN batches, total, updateStatistics;