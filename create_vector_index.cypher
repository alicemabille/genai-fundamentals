/***
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/rec-embed/movie-plot-embeddings-1k.csv'
AS row
MATCH (m:Movie {movieId: row.movieId})
CALL db.create.setNodeVectorProperty(m, 'plotEmbedding', apoc.convert.fromJsonList(row.embedding));
***/

/**CALL apoc.periodic.iterate(
    '
    MATCH (k:Knowledge)
    YIELD k
    ',
    // create embedding of description of current knowledge
    '
    WITH ai.text.embed(
        k.description,
        "Ollama",
        { token: "sk-...", model: "text-embedding-ada-002" }
    ) AS embedding
    RETURN toFloatList(embedding)
    '
)**/

CREATE VECTOR INDEX knowledgeDescriptions IF NOT EXISTS
FOR (k:Knowledge)
ON k.descriptionEmbedding
OPTIONS {indexConfig: {
 `vector.dimensions`: 1536,
 `vector.similarity_function`: 'cosine'
}};