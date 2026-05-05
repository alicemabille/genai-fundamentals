import os
from dotenv import load_dotenv
load_dotenv()

from neo4j import GraphDatabase
from neo4j_graphrag.embeddings.ollama import OllamaEmbeddings
from neo4j_graphrag.retrievers import VectorRetriever

# Connect to Neo4j database
driver = GraphDatabase.driver(
    os.getenv("NEO4J_URI"), 
    auth=(
        os.getenv("NEO4J_USERNAME"), 
        os.getenv("NEO4J_PASSWORD")
    )
)

# Create embedder
embedder = OllamaEmbeddings(model=os.getenv("EMBEDDING_MODEL"))

# Create retriever
retriever = VectorRetriever(
    driver,
    neo4j_database=os.getenv("NEO4J_DATABASE"),
    index_name="knowledgeDescriptions",
    embedder=embedder,
    return_properties=["id", "label", "description"],

)

# Search for similar items
result = retriever.search(query_text="conjugaison", top_k=5)

# Parse results
for item in result.items:
    print(item.content, item.metadata["score"])

# CLose the database connection
driver.close()
