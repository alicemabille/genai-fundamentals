import os
from dotenv import load_dotenv
load_dotenv()

from neo4j import GraphDatabase
from neo4j_graphrag.embeddings.ollama import OllamaEmbeddings
from neo4j_graphrag.llm import OllamaLLM
from neo4j_graphrag.generation import GraphRAG
from neo4j_graphrag.retrievers import VectorCypherRetriever

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

# Define retrieval query
retrieval_query = """
MATCH (k:Knowledge)<-[r]-()
RETURN 
    k.id AS id,
    k.label AS label,
    k.description AS description,
    k.type AS type,
    score AS similarityScore,
    COLLECT {
        MATCH (k)-[]->(k1:Knowledge)
        RETURN {
            id: k1.id,
            label: k1.label,
            description: k1.description,
            type: k1.type
        }
    } AS relatedKnowledges
"""

# Create retriever
retriever = VectorCypherRetriever(
    driver,
    neo4j_database=os.getenv("NEO4J_DATABASE"),
    index_name="knowledgeDescriptions",
    embedder=embedder,
    retrieval_query=retrieval_query,
)

#  Create the LLM
llm = OllamaLLM(model_name=os.getenv("LLM_NAME")) # ollama pull ministral-3:3b

# Create GraphRAG pipeline
rag = GraphRAG(retriever=retriever, llm=llm)

# Search
query_text = "aide-moi à m'améliorer en conjugaison"

response = rag.search(
    query_text=query_text, 
    retriever_config={"top_k": 5},
    return_context=True
)

print(response.answer)
print("CONTEXT:", response.retriever_result.items)

# Close the database connection
driver.close()