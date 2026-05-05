import os
from dotenv import load_dotenv
load_dotenv()

from neo4j import GraphDatabase
from neo4j_graphrag.embeddings.ollama import OllamaEmbeddings
from neo4j_graphrag.retrievers import VectorRetriever
from neo4j_graphrag.llm import OllamaLLM
from neo4j_graphrag.generation import GraphRAG

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

# Create the LLM
llm = OllamaLLM(model_name=os.getenv("LLM_NAME"))

# Create GraphRAG pipeline
rag = GraphRAG(retriever=retriever, llm=llm)

# Search 
query_text = "Aide-moi à apprendre la conjugaison des temps du passé"

response = rag.search(
    query_text=query_text, 
    retriever_config={"top_k": 5},
    return_context=True
)

print(response.answer)
print("CONTEXT:", response.retriever_result.items)

# CLose the database connection
driver.close()