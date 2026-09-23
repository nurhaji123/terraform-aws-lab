# AWS Infrastructure Lab — Terraform

A single-region AWS environment built with Terraform: VPC networking, an
Apache web server, IAM instance roles, S3/EBS/RDS storage, CloudWatch
alarms wired to Lambda, and a VPC peering connection.

Applied against a real AWS account, then destroyed. This repository holds
the configuration and the run evidence, not a live environment.

## Architecture

```
                       Internet
                           |
                    [Internet Gateway]
                           |
   ┌───────────────────── VPC 10.0.0.0/16 ─────────────────────┐
   │                                                            │
   │  Public subnets (10.0.1.0/24, 10.0.2.0/24)                │
   │    ├─ EC2 web server (Apache, IAM role: S3 read-only)     │
   │    ├─ Security group: SSH from one IP, HTTP from anywhere │
   │    └─ Network ACL: subnet-level stateless filtering       │
   │                                                            │
   │  Private subnets (10.0.101.0/24, 10.0.102.0/24)           │
   │    └─ RDS MySQL — no route to the Internet Gateway        │
   │                                                            │
   └───────────────────────────┬────────────────────────────────┘
                               │ VPC peering
   ┌───────────────────────────┴────────────────────────────────┐
   │  Peer VPC 10.1.0.0/16                                      │
   └────────────────────────────────────────────────────────────┘

   CloudWatch alarm (CPU ≥ 50% / 5 min) ──▶ Lambda (Python 3.13)
   S3 buckets ×2, versioned, public access blocked
```

## Layout

| File | Contents |
|---|---|
| `main.tf` | VPC, Internet Gateway, public subnets, public route table |
| `security.tf` | Web security group, network ACL and rules |
| `ec2.tf` | Key pair, web server instance, user data |
| `iam.tf` | EC2 assume-role policy, S3 read-only policy, instance profile |
| `storage.tf` | S3 buckets, EBS volume and attachment, RDS instance |
| `rds.tf` | Private subnets, private route tables, DB subnet group, DB security group |
| `s3_security.tf` | Public access blocks |
| `monitoring.tf` | Lambda packaging, execution role, CloudWatch alarm, invoke permission |
| `peering.tf` | Peer VPC, peering connection, accepter, cross-VPC routes |
| `backend.tf` | Partial S3 backend declaration |

## Design decisions

**Remote state with native S3 locking.** State lives in S3 with
`use_lockfile = true`, which uses S3 conditional writes for the lock. This
replaces the DynamoDB lock table that most older material still shows —
one fewer resource to provision and pay for.

**Partial backend configuration.** `backend.tf` declares the backend but
omits the bucket and key, which are supplied at init time from a gitignored
`backend.hcl`. The bucket name embeds the AWS account ID, so committing it
would publish the account number.

**Network ACLs are stateless; security groups are not.** The security group
needs only an inbound rule for a service — return traffic is tracked
automatically. The NACL needs explicit inbound rules on ephemeral ports
1024–65535 for return traffic, in both TCP and UDP. The UDP rule is what
makes DNS work; without it, `yum` in the user data hangs on name resolution
while the subnet appears otherwise healthy.

**Database ingress by security group, not CIDR.** The RDS security group
allows 3306 from the web server's security group ID rather than a subnet
range. The rule stays correct if the instance is replaced, moved between
subnets, or scaled out.

**AMI pinned by variable.** `most_recent = true` on an AMI data source means
an upstream Amazon Linux release can replace the instance during an
unrelated plan. The AMI is a variable with a pinned default instead, so
upgrades are an explicit change with a visible diff.

**Private subnets have no NAT Gateway.** RDS needs no outbound internet
access, and a NAT Gateway costs roughly $32/month before data charges. The
private route tables are deliberately left without a default route.

**Resources created with `count`.** Subnets and buckets use `count` because
they are homogeneous and index-addressed. `for_each` would be the better
choice if they had distinct per-item configuration, since removing a middle
element from a `count` list renumbers everything after it.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in real values

cat > backend.hcl << 'EOF'
bucket = "your-state-bucket-name"
key    = "webserver/terraform.tfstate"
EOF

terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

The database password is read from `var.db_password`. Supply it via
`TF_VAR_db_password` rather than writing it into `terraform.tfvars`.

An SSH keypair is expected at the path in `var.ssh_public_key_path`:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/tf-web-server -C terraform-web-server
```

## Known limitations

These are deliberate scope choices for a lab, not oversights:

- **RDS is not encrypted at rest.** `storage_encrypted` cannot be changed in
  place; enabling it forces replacement of the database.
- **The database password passes through Terraform state**, where it is
  stored in plaintext. Production would use `manage_master_user_password`
  with Secrets Manager, removing the password from state entirely.
- **SSH is open to a single public IP.** SSM Session Manager would remove
  the need for port 22 and the key pair altogether.
- **No modules.** Everything is flat, which suits a single environment but
  does not scale to dev/staging/prod without duplication.
- **No CI.** `fmt`, `validate`, `tflint` and `checkov` in a pipeline would
  catch most of the above before merge.
- **Single region, single AZ for the database.** `multi_az = false` to keep
  the lab inside free-tier limits.

## Cost

Everything here was destroyed after testing. If applied, the RDS instance
and EC2 instance accrue charges outside free-tier eligibility — the database
is the significant one.
