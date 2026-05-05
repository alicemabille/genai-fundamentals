import os
from dotenv import load_dotenv
load_dotenv()

import neo4j
from neo4j_graphrag.embeddings.ollama import OllamaEmbeddings

URI = os.getenv("NEO4J_URI")
AUTH = (os.getenv('NEO4J_USERNAME'), os.getenv('NEO4J_PASSWORD'))
DB_NAME = os.getenv('NEO4J_DATABASE')


def main():
    with neo4j.GraphDatabase.driver(URI, auth=AUTH) as driver:
        driver.verify_connectivity()

        embedder = OllamaEmbeddings(model=os.getenv("EMBEDDING_MODEL"))

        batch_size = 100
        batch_n = 1
        knowledges_with_embeddings = []
        with driver.session(database=DB_NAME) as session:
            # Fetch `Knowledge` nodes
            result = session.run('MATCH (k:Knowledge) RETURN k.description AS description, k.label AS label')
            for record in result:
                label = record.get('label')
                description = record.get('description')

                # Create embedding for label and description
                if label is not None and description is not None:
                    knowledges_with_embeddings.append({
                        'label': label,
                        'description': description,
                        'embedding': embedder.embed_query(f'''
                            label: {label}\n
                            description: {description}
                        '''),
                    })

                # Import when a batch of knowledges has embeddings ready; flush buffer
                if len(knowledges_with_embeddings) == batch_size:
                    import_batch(driver, knowledges_with_embeddings, batch_n)
                    knowledges_with_embeddings = []
                    batch_n += 1

            # Flush last batch
            import_batch(driver, knowledges_with_embeddings, batch_n)

        # Import complete, show counters
        records, _, _ = driver.execute_query('''
        MATCH (m:Knowledge WHERE m.embedding IS NOT NULL)
        RETURN count(*) AS countKnowledgesWithEmbeddings, size(m.embedding) AS embeddingSize
        ''', database_=DB_NAME)
        print(f"""
    Embeddings generated and attached to nodes.
    Knowledge nodes with embeddings: {records[0].get('countKnowledgesWithEmbeddings')}.
    Embedding size: {records[0].get('embeddingSize')}.
        """)


def import_batch(driver, nodes_with_embeddings, batch_n):
    # Add embeddings to Knowledge nodes
    driver.execute_query('''
    UNWIND $knowledges as knowledge
    MATCH (m:Knowledge {label: knowledge.label, description: knowledge.description})
    CALL db.create.setNodeVectorProperty(m, 'embedding', knowledge.embedding)
    ''', knowledges=nodes_with_embeddings, database_=DB_NAME)
    print(f'Processed batch {batch_n}.')


if __name__ == '__main__':
    main()