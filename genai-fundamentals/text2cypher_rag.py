import os
from dotenv import load_dotenv
load_dotenv()

from neo4j import GraphDatabase
from neo4j_graphrag.llm import OllamaLLM
from neo4j_graphrag.generation import GraphRAG
from neo4j_graphrag.retrievers import Text2CypherRetriever

# Connect to Neo4j database
driver = GraphDatabase.driver(
    os.getenv("NEO4J_URI"), 
    auth=(
        os.getenv("NEO4J_USERNAME"), 
        os.getenv("NEO4J_PASSWORD")
    )
)

# Create LLM 
t2c_llm = OllamaLLM(
    model_name=os.getenv('LLM_NAME')
)


# Build the retriever
retriever = Text2CypherRetriever(
    driver=driver,
    neo4j_database=os.getenv('NEO4J_DATABASE'),
    llm=t2c_llm
)

llm = OllamaLLM(model_name=os.getenv('LLM_NAME'))
rag = GraphRAG(retriever=retriever, llm=llm)

query_text = "Quelles connaissances sont liées à la conjugaison du verbe 'être' au passé simple ?"

response = rag.search(
    query_text=query_text,
    return_context=True
    )

print(response.answer)
print("CYPHER :", response.retriever_result.metadata["cypher"])
print("CONTEXT:", response.retriever_result.items)

driver.close()
