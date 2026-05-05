// run this after having created emmbeddings

CREATE VECTOR INDEX knowledgeDescriptions IF NOT EXISTS
FOR (k:Knowledge)
ON k.embedding
OPTIONS {indexConfig: {
 `vector.dimensions`: 768,
 `vector.similarity_function`: 'cosine'
}};