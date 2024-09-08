# Secure Multiparty computation with Nitro Enclaves


## IAM set-up two
- TODO: Limit resources here
- Create policy `KMSEncryptDecrypt`:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt",
                "kms:Encrypt"
            ],
            "Resource": "*"
        }
    ]
} 
```
- Create the policy `S3GetPut`:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "*"
        }
    ]
}
```
- Create the role `DataOwnerRoleForEC2` with `KMSEncryptDecrypt` and `S3GetPut`:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

**MPC Service only**:
- Create the policy `EnclaveActions`:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "sts:AssumeRole",
                "kms:Decrypt"
            ],
            "Resource": [
                "arn:aws:kms:eu-central-1:381491854648:key/mrk-a59e284c2cc44872bd9a59898bc4ac9e",
                "arn:aws:kms:eu-central-1:390844748441:key/mrk-e4049dac6a9a423c8ef8869149ca3841",
                "arn:aws:s3:::ledidi-phd-dataowner1/*",
                "arn:aws:s3:::ledidi-phd-dataowner2/*",
                "arn:aws:s3:::ledidi-phd-mpc-service/*",
                "arn:aws:iam::381491854648:role/MPCServiceRole"
            ]
        }
    ]
}
```
- Create an IAM EC2 instance role, `MPCServiceRoleForEC2`
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
}
```
- TODO: With no permissions?
- Attach the policy `EnclaveActions` to `MPCServiceRoleForEC2`
- Update the trust policy (Trust relationships) to `MPCServiceRoleForEC2`
    - TODO: Correct with `"AWS": "arn:aws:iam::381491854648:role/MPCServiceRoleForEC2"` added to `Principal`?
    - TODO: Is this necessary?


## KMS set-up
- Create a (multi-region) symmetric encryption key
- Key administrators: TODO, figure out
    - Trying without any
- Key usage permissions: TODO
    - Trying with either `MPCServiceRoleForEC2` or `DataOwnerRoleForEC2`
- TODO: Add another AWS account for users?
- TODO: Add option for external key material
- Data owner 1:
    - Key ARN: arn:aws:kms:eu-central-1:381491854648:key/mrk-a59e284c2cc44872bd9a59898bc4ac9e
    - Key ID: mrk-a59e284c2cc44872bd9a59898bc4ac9e
- Data owner 2:
    - Key ARN: arn:aws:kms:eu-central-1:390844748441:key/mrk-e4049dac6a9a423c8ef8869149ca3841
    - Key ID: mrk-e4049dac6a9a423c8ef8869149ca3841


## S3 set-up
- Create a bucket for each data owner and the MPC service
- TODO: Figure out how to keep the settings as restrictive as possible
- TODO: What encryption to use?
- Buyer 1: arn:aws:s3:::ledidi-phd-buyer1
- Buyer 2: arn:aws:s3:::ledidi-phd-dataowner2
- MPC service: arn:aws:s3:::ledidi-phd-mpc-service
- Update Bucket policy for data owners
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::381491854648:role/MPCServiceRole"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::ledidi-phd-dataowner1/*"
        }
    ]
}
```


## EC2 set-up
- Use X86 instances with AL2023
- Sizes
    - Data owner: t2.medium with 16GB storage
    - Parent: c5.xlarge
- **NOTE**: Use public subnet
- Enable EBS encryptions
    - TODO: What effect does this really have?
- **PARENT**: Enable enclave for parent instance
- Attach IAM instance role with permissions to encrypt/decrypt and get/put objects


## Instance set-up
- Install packages: `sudo dnf install git-all aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel -y`
- Update permissions: `sudo usermod -aG ne $USER && sudo usermod -aG docker $USER`
- Enable docker and reboot: `sudo systemctl enable --now docker && sudo reboot`
- **PARENT ONLY:**
    - `sudo systemctl enable --now nitro-enclaves-allocator.service`
    - `sudo systemctl enable --now nitro-enclaves-vsock-proxy.service`
    - `sudo nano /etc/nitro_enclaves/allocator.yaml` (4096 mib)
    - Install application dependencies:
        - `sudo dnf install -y python3 python3-pip`
        - `sudo pip3 install boto3 pandas`


## MPC application set-up
- Clone repo: `git clone https://github.com/aws-samples/aws-nitro-enclaves-bidding-service.git`
- Build kmstool-enclave-cli
    - `git clone https://github.com/aws/aws-nitro-enclaves-sdk-c.git`
    - `cd aws-nitro-enclaves-sdk-c/bin/kmstool-enclave-cli && ./build.sh`
    - `cp kmstool_enclave_cli ~/aws-nitro-enclaves-bidding-service/`
    - `cp libnsm.so ~/aws-nitro-enclaves-bidding-service/`
- Update `vsock-poc.py` to use the correct bucket names and ARN values
- ??? Update AWS region in `script/update_enclave.sh`
- Build container: `docker build -t vsock-poc .`
- Build enclave image: `sudo nitro-cli build-enclave --docker-uri vsock-poc --output-file ~/vsock_poc.eif`
    - Save PCR values for KMS condition keys (only data owners?)
- TODO: Build kmstool in dockerfile
```
{
  "Measurements": {
    "HashAlgorithm": "Sha384 { ... }",
    "PCR0": "3288b83651eb19c4f7db273cd8aae1d32311eb5fa9ef68658dfd75ce687262b291f412a6722e7e3ad738be7951d5afa2",
    "PCR1": "4b4d5b3661b3efc12920900c80e126e4ce783c522de6c02a2a5bf7af3a2b9327b86776f188e4be1c1c404a129dbda493",
    "PCR2": "1a71a191dd038a76293bd9c61531dbe926d7ce628d99e07e407949aa96b3d918d3c83e576d4c9e3c2605eda50621a958"
  }
}
```


## Data owner set-up
- Create encrypted file: `cd aws-nitro-enclaves-bidding-service/scripts && ./generate_bidder_1_bids.sh`
- Upload to S3: `aws s3 cp encrypted.csv s3://ledidi-phd-dataowner1`

- Update key policies
    - Add `MPCServiceRole` as principal
    - Add condition to "Allow use of the key" statement
