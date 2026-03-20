This deployment uses an EC2 instance to run a two-tier WordPress application inside Docker containers. WordPress runs in one container and MySQL runs in another. The MySQL data directory is mapped to an attached EBS volume mounted on the host at /mnt/mysql-data so the database container restarts and rebuilds. Connect to the EC2 public IP over HTTP. Docker publishes the WordPress service on port 80.

I used an EBS volume for MySQL because database storage needs to be persistent, while containers are meant to be replaceable. If MySQL stored its files only inside the container filesystem, the data could be lost if the container were deleted or replaced. By mounting the MySQL data directory to /mnt/mysql-data, the database files are not easily lost. A container recreation could wipe the database state. WordPress would effectively reset because the content and configuration in MySQL would no longer exist.

22/TCP (SSH): for administrative access to the EC2 instance.
80/TCP (HTTP): so users can reach the WordPress site in a browser.
There is no need for internet clients to connect directly to the database. The main security risks in the current design are:
HTTP is unencrypted if I only expose port 80.
Login credentials and session traffic are more exposed than they would be under HTTPS.
SSH can be risky if open too broadly.
Port 22 should ideally be limited to my IP address rather than open to the world.
A single host is a single point of failure. If the EC2 instance is compromised or fails, both the web tier and database tier are affected at the same time.

If the EC2 instance crashed right now, the website would go offline because both containers depend on that single host. WordPress and MySQL would stop running, and users would not be able to access the site until the instance is relaunched or replaced.

What would likely survive:
MySQL data on the EBS volume should survive because EBS is persistent block storage and exists independently of the running container.
Any backups already uploaded to S3 would also survive.

What would likely be lost or interrupted:
The running containers would stop.
Any files stored only on the instance root filesystem and not backed up or mounted to persistent storage could be lost if the instance had to be rebuilt.


Run multiple WordPress application instances behind an Application Load Balancer instead of one EC2 instance.
Use Auto Scaling so the application tier can grow or shrink with demand.
Consider using Amazon RDS and other AWS database services.

