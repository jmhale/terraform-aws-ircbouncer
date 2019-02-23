# Output file
output "irc_eip" {
  value = "${aws_eip.irc_eip.public_ip}"
}
