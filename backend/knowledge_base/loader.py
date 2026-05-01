import chromadb
from chromadb.utils import embedding_functions
import os
import glob
from pypdf import PdfReader

# Initialize ChromaDB persistent client
CHROMA_DIR = os.path.join(os.path.dirname(__file__), "chroma_store")
client = chromadb.PersistentClient(path=CHROMA_DIR)

# Use default embedding function (sentence transformers)
embedding_fn = embedding_functions.DefaultEmbeddingFunction()

collection = client.get_or_create_collection(
    name="insurance_policies",
    embedding_function=embedding_fn
)

def load_pdf_text(pdf_path: str) -> str:
    """Extract text from a PDF file."""
    reader = PdfReader(pdf_path)
    text = ""
    for page in reader.pages:
        text += page.extract_text() or ""
    return text

def chunk_text(text: str, chunk_size: int = 500) -> list[str]:
    """Split text into overlapping chunks."""
    words = text.split()
    chunks = []
    for i in range(0, len(words), chunk_size - 50):
        chunk = " ".join(words[i:i + chunk_size])
        if chunk:
            chunks.append(chunk)
    return chunks

def ingest_policies():
    """Load all PDFs from sample_policies/ into ChromaDB."""
    pdf_dir = os.path.join(os.path.dirname(__file__), "sample_policies")
    pdf_files = glob.glob(os.path.join(pdf_dir, "*.pdf"))

    if not pdf_files:
        print("No PDFs found. Adding sample policy text for demo.")
        sample_text = """
        BlueCross Policy Coverage Rules:
        Prior authorization is required for all specialty medications exceeding $500/month.
        Mental health services require a referral from primary care physician.
        Step therapy is required: patient must try generic alternatives before brand-name drugs.
        MRI and CT scans require pre-authorization. X-rays do not require pre-authorization.
        Oncology treatments require specialist referral and diagnosis documentation.
        """
        collection.add(
            documents=[sample_text],
            ids=["sample_policy_1"],
            metadatas=[{"insurer": "BlueCross", "type": "general_coverage"}]
        )
        print("Sample policy loaded.")
        return

    for pdf_path in pdf_files:
        text = load_pdf_text(pdf_path)
        chunks = chunk_text(text)
        insurer_name = os.path.basename(pdf_path).replace(".pdf", "")
        
        ids = [f"{insurer_name}_chunk_{i}" for i in range(len(chunks))]
        metadatas = [{"insurer": insurer_name, "chunk": i} for i in range(len(chunks))]
        
        collection.add(documents=chunks, ids=ids, metadatas=metadatas)
        print(f"Loaded {len(chunks)} chunks from {insurer_name}")

def query_policies(query: str, insurer: str = None, n_results: int = 5) -> list[str]:
    """Query the knowledge base for relevant policy sections."""
    where = {"insurer": insurer} if insurer else None
    results = collection.query(
        query_texts=[query],
        n_results=n_results,
        where=where
    )
    return results["documents"][0] if results["documents"] else []

if __name__ == "__main__":
    ingest_policies()
    print("Knowledge base ready.")
    # Test query
    results = query_policies("prior authorization requirements for MRI")
    print(f"Test query returned {len(results)} results.")

