import os
import gzip
import csv
import time
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from google.api_core.exceptions import ResourceExhausted, DeadlineExceeded
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

# Initialize Firebase Admin SDK
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)

# Get a Firestore client
db = firestore.client()

@retry(
    stop=stop_after_attempt(10),
    wait=wait_exponential(multiplier=1, min=4, max=60),
    retry=retry_if_exception_type((ResourceExhausted, DeadlineExceeded))
)
def commit_batch(batch):
    batch.commit()

def read_csv_gz_in_batches(file_path, batch_size=500):
    with gzip.open(file_path, 'rt') as f:
        reader = csv.DictReader(f)
        batch = []
        for row in reader:
            batch.append(row)
            if len(batch) == batch_size:
                yield batch
                batch = []
        if batch:  # Don't forget the last batch if it's smaller than batch_size
            yield batch

def upload_csv_gz_to_firestore(file_path, batch_size=500):
    filename = os.path.splitext(os.path.basename(file_path))[0]
    total_rows = 0
    start_time = time.time()
    
    for csv_batch in read_csv_gz_in_batches(file_path, batch_size):
        firestore_batch = db.batch()
        
        for row in csv_batch:
            doc_ref = db.collection('uploads').document(f"{filename}_{total_rows}")
            firestore_batch.set(doc_ref, row)
            total_rows += 1
        
        commit_batch(firestore_batch)
        
        elapsed_time = time.time() - start_time
        rows_per_second = total_rows / elapsed_time
        print(f"Committed {total_rows} documents. Speed: {rows_per_second:.2f} rows/second")

    print(f"Finished uploading {total_rows} documents from {file_path}.")
    print(f"Total time: {elapsed_time:.2f} seconds")
    print(f"Average speed: {rows_per_second:.2f} rows/second")

def main():
    input_dir = 'data/input'
    csv_gz_files = [f for f in os.listdir(input_dir) if f.endswith('.csv.gz')]
    
    for file in csv_gz_files:
        file_path = os.path.join(input_dir, file)
        print(f"Starting upload for {file}")
        upload_csv_gz_to_firestore(file_path)
        print(f"Finished uploading {file}")
        time.sleep(5)  # Short pause between files

if __name__ == "__main__":
    main()