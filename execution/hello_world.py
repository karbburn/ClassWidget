import datetime
import os

def main():
    print("Hello from the Execution Layer!")
    print(f"Current Timestamp: {datetime.datetime.now()}")
    
    # Verify .tmp directory access
    tmp_path = os.path.join(".tmp", "verification.txt")
    with open(tmp_path, "w") as f:
        f.write("Verification successful.")
    
    print(f"Validated .tmp access: {tmp_path}")

if __name__ == "__main__":
    main()
