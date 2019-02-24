resource "aws_security_group" "irc-instance-sg" {
  name        = "irc-instance-sg"
  description = "Terraform Managed. SG for IRC bouncer instance."
  vpc_id      = "${var.vpc_id}"

  tags {
    Name       = "irc-instance-sg"
    Project    = "irc"
    tf-managed = "True"
  }

  ingress {
    from_port   = 6697
    to_port     = 6697
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allows IRC traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allows SSL traffic for Certbot"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allows HTTP traffic for Certbot. Temp needed because of LE issue."
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "irc-bouncer-instance" {
  ami                    = "${var.ami_id}"
  instance_type          = "t2.nano"
  key_name               = "${var.ssh_key_id}"
  subnet_id              = "${var.public_subnet_ids[0]}"
  vpc_security_group_ids = ["${aws_security_group.irc-instance-sg.id}", "${var.ingress_security_group_id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.ircbouncer_iamprofile_buildartifacts.name}"

  user_data = <<EOF
#!/bin/bash
apt-get update
apt-get upgrade -y
add-apt-repository -y ppa:certbot/certbot
apt-get update
apt-get install -y znc znc-dev software-properties-common certbot awscli
useradd --create-home -d /var/lib/znc --system --shell /sbin/nologin --comment "Account to run ZNC daemon" --user-group znc
# Drop in a systemd unit for ZNC, since it doesn't come with one by default
echo W1VuaXRdCkRlc2NyaXB0aW9uPVpOQywgYW4gYWR2YW5jZWQgSVJDIGJvdW5jZXIKQWZ0ZXI9bmV0d29yay1vbmxpbmUudGFyZ2V0CgpbU2VydmljZV0KRXhlY1N0YXJ0PS91c3IvYmluL3puYyAtZiAtLWRhdGFkaXI9L3Zhci9saWIvem5jClVzZXI9em5jCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK | base64 --decode > /etc/systemd/system/znc.service
systemctl daemon-reload
aws s3 sync s3://dogsec-build-artifacts/znc/ /var/lib/znc/
chown -R znc:znc /var/lib/znc/*
certbot certonly --standalone -d irc.dogsec.io -m dog@dogsec.io --agree-tos -n
cat /etc/letsencrypt/live/irc.dogsec.io/privkey.pem /etc/letsencrypt/live/irc.dogsec.io/fullchain.pem > /var/lib/znc/configs/irc.dogsec.io.pem
systemctl enable znc
systemctl start znc
# Overwrite default certbot cron file with ours that includes renewal hooks for ZNC restart
echo U0hFTEw9L2Jpbi9zaApQQVRIPS91c3IvbG9jYWwvc2JpbjovdXNyL2xvY2FsL2Jpbjovc2JpbjovYmluOi91c3Ivc2JpbjovdXNyL2JpbgoKMCAqLzEyICogKiAqIHJvb3QgdGVzdCAteCAvdXNyL2Jpbi9jZXJ0Ym90IC1hIFwhIC1kIC9ydW4vc3lzdGVtZC9zeXN0ZW0gJiYgcGVybCAtZSAnc2xlZXAgaW50KHJhbmQoMzYwMCkpJyAmJiAvdXNyL2Jpbi9jZXJ0Ym90IC1xIHJlbmV3IC0tcmVuZXctaG9vayAiY2F0IC9ldGMvbGV0c2VuY3J5cHQvbGl2ZS9pcmMuZG9nc2VjLmlvL3ByaXZrZXkucGVtIC9ldGMvbGV0c2VuY3J5cHQvbGl2ZS9pcmMuZG9nc2VjLmlvL2Z1bGxjaGFpbi5wZW0gPiAvdmFyL2xpYi96bmMvY29uZmlncy9pcmMuZG9nc2VjLmlvLnBlbSIgLS1yZW5ldy1ob29rICJzeXN0ZW1jdGwgcmVzdGFydCB6bmMi | base64 --decode > /etc/cron.d/certbot
EOF

  tags {
    Name       = "irc-bouncer"
    Project    = "irc"
    tf-managed = "True"
  }
}

resource "aws_eip" "irc_eip" {
  instance = "${aws_instance.irc-bouncer-instance.id}"
  vpc      = true
}
