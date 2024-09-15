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
