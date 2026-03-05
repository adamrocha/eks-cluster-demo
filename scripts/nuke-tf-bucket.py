#!/usr/bin/env python3
import os
import sys

import boto3
from botocore.exceptions import BotoCoreError, ClientError


def main() -> int:
    s3_bucket = os.getenv("S3_BUCKET", "terraform-state-bucket-2727")
    aws_region = os.getenv("AWS_REGION", "us-east-1")
    force = os.getenv("FORCE", "0") == "1"
    dry_run = os.getenv("DRY_RUN", "0") == "1"

    if force:
        confirm = "y"
    else:
        print(f"⚠️  WARNING: This will delete the S3 bucket: {s3_bucket}")
        confirm = input("Are you sure? (y/N): ").strip()

    if confirm != "y":
        print("❎ Aborted.")
        return 0

    s3 = boto3.client("s3", region_name=aws_region)

    print("🔄 Scanning bucket for versioned objects...")

    try:
        while True:
            response = s3.list_object_versions(Bucket=s3_bucket)

            versions = response.get("Versions", [])
            delete_markers = response.get("DeleteMarkers", [])

            objects_to_delete = [
                {"Key": item["Key"], "VersionId": item["VersionId"]}
                for item in versions + delete_markers
            ]

            count = len(objects_to_delete)
            if count == 0:
                break

            print(f"   found {count} objects...")

            for start in range(0, count, 1000):
                batch = objects_to_delete[start : start + 1000]
                batch_count = len(batch)

                if batch_count == 0:
                    continue

                if dry_run:
                    print(f"   [DRY RUN] would delete {batch_count} objects:")
                    for item in batch:
                        print(f"{item['Key']} ({item['VersionId']})")
                else:
                    print(f"   deleting {batch_count} objects...")
                    s3.delete_objects(
                        Bucket=s3_bucket,
                        Delete={"Objects": batch, "Quiet": False},
                    )

            if dry_run:
                break

        if dry_run:
            print("❎ DRY RUN complete. Bucket NOT deleted.")
        else:
            print("❌ Deleting bucket...")
            s3.delete_bucket(Bucket=s3_bucket)
            print(f"✅ Bucket {s3_bucket} deleted.")

        return 0

    except (BotoCoreError, ClientError) as error:
        print(f"❌ AWS error: {error}")
        return 1
    except KeyboardInterrupt:
        print("\n❎ Aborted.")
        return 130


if __name__ == "__main__":
    sys.exit(main())
