#!/bin/bash

CON_PUB="/tmp/console.pub"
I_PUB="/tmp/instance.pub"
OUT_TMP="/tmp/console-import.output"
IMPORT_KEY_APP="/tmp/import-key.rb"

trap "rm -f $I_PUB $CON_PUB $OUT_TMP; exit" INT TERM EXIT

# Keys are an array of keys containing <key file name without .pem> <account id> <access key> <secret key>
# example:
# keys[0]="mykey 1234567890 1WEAS143612463SAD +M7/34614QWETS#4613461611346ASD"
# the key file above would be in your ~/.ssh directory and be named mykey.pem

#keys[0]="nytd.clienttech.dev 119421858375 <accesskey> <secretkey>"
#keys[1]="nytdplatform.prod 771521388140 <accesskey> <secretkey>"
#keys[2]="nytdplatform.dev 155565490060 <accesskey> <secretkey>"
#keys[3]="nytdplatform.wtlogs 935814720612 <accesskey> <secretkey>"

export GNUPGHOME=/var/nyt/www/console/pki
export HERD_KEY=/var/nyt/gnupg



cat <<'EOF' >> $IMPORT_KEY_APP
#!/usr/bin/env ruby

require 'rubygems'
require 'herd'


if ARGV.length != 4
	puts "Usage: #{File.basename $0} <main-key-name> <keychain-path> <key-name-to-import> <path-of-key-to-import>"
	exit 1
elsif not File.exists? ARGV[1] or not File.readable? ARGV[1] or not File.directory? ARGV[1]
	puts "Key chain path does not exist, or is not readable, or is not a directory!"
	exit 1
elsif not File.exists? ARGV[3] or not File.readable? ARGV[3]
	puts "key to import is not readable or doesn't exist!"
	exit 1
end


MY_NAME  = ARGV[0]
KC_PATH  = ARGV[1]
KEY_NAME = ARGV[2]
KEY_PATH = ARGV[3]

begin
	keychain = Herd::GPG.new(MY_NAME, KC_PATH)
	
	if not keychain.key(KEY_NAME).nil?
		keychain.delete(keychain.key(KEY_NAME))
	end
	
	new_key = keychain.import(IO.read(KEY_PATH))
	keychain.sign_key(new_key, keychain.signing_key)
	keychain.change_key_trust(new_key, :full)
rescue Exception => e
	puts "---FAILED IMPORT---"
	puts "Exception: #{e.class}: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
	puts "---FAILED IMPORT---"
	exit 1
end

exit 0

EOF

chmod ug+x $IMPORT_KEY_APP


gpg --export --armor console > $CON_PUB

already_have_keys_for="$(gpg --list-keys 2>/dev/null | grep -Eio 'i-[a-z0-9]+' | tr "\n" "|" | sed -e 's%|$%%')"

for (( i = 0; i < ${#keys[@]}; i++ )); do
	cat <(echo ${keys[$i]}) | while read key id access secret; do  
		export AWS_ACCESS_KEY=$access
		export AWS_SECRET_KEY=$secret
		export AWS_KEY=/root/.ssh/$key.pem

		echo "Working on account: $key "

		for instance in $( list-instances | grep running | grep flock-managed | grep -vE "(${already_have_keys_for})" | awk '{ print $1 }'); do
			echo "  Instance: $instance"
			echo "      Pushing necessary files to instance..."
			copy-to-instance $CON_PUB $CON_PUB $instance >/dev/null 2>&1
			copy-to-instance $IMPORT_KEY_APP $IMPORT_KEY_APP $instance >/dev/null 2>&1

			echo "      Importing console key to instance..."
			run-cmd-instance "
				chmod ug+x $IMPORT_KEY_APP; 
				if [ ! -x /sbin/rngd ]; then
					echo '        Installing RNGD...'
					yum install -y rng-utils 1>/dev/null 2>/dev/null
					rngd -r /dev/urandom -b
				fi
				$IMPORT_KEY_APP $instance $HERD_KEY console $CON_PUB
			" $instance > $OUT_TMP

			if [ $(grep -c -- '---FAILED IMPORT---' $OUT_TMP) -eq 0 ]; then
				echo "      Getting instances public key..."
				run-cmd-instance "gpg --homedir $HERD_KEY --export --armor $instance 2>/dev/null" $instance > $I_PUB

				echo "      Importing instances public key..."
				$IMPORT_KEY_APP console $GNUPGHOME $instance $I_PUB
			
				echo "      done."
			else 
				cat $OUT_TMP
				echo "      FAILED..."
			fi
		done

		unset AWS_ACCESS_KEY AWS_SECRET_KEY AWS_KEY
	done
done
