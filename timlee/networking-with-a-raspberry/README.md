# Networking with a Raspberry

_[Tim Lee](../) — 21st January 2021_

Want to learn about networking, proxies and web servers? Read on.

As a developer, I have always felt comfortable and safe _in the code_. But etc..

## What this post covers

For this blog, let's pretend you're in the office of your company headquarters, Badgers 4 U, because offices are still a thing that people go to. You want to set up a really cool internal site so that people can vote on their favourite types of Badger. To do that we'll need to cover off a few things:

- [Setting up a web server](#setting-up-a-web-server)
- [Configuring DNS](#where-are-you?-dns-comes-first)
- Creating SSL certificates
- Using a reverse proxy
- Bonus! Setting up a forward proxy

## What you will need

A Raspberry Pi (I used a Raspberry Pi 4b) connected to your local WiFi network. However, you can run everything from another device on your network, or at a push, right on your computer.

## No place like home (setting up a web server)

If you want people to be able to access your site then you need to be able to give it to them. For this you need a web server. This will store your site and hand it out to anyone who comes asking.

A web server is just some software running on a networked machine. It can be dumb, like a file server used to serve static documents (might sound familiar if you've ever used an AWS S3 bucket) or a bit smarter, interpreting requests and doing some processing to assimilate results to API requests or dynamically render web pages.

So which software to use? There are many popular options including<sup>[1](#1)</sup>:

- Apache - open source, around since 1995, serves around 25% of the web
- Nginx - open source, released in 2004, more performant than Apache and has been growing in popularity and has stolen significant market share from Apache, currently serves around 37% of the web
- IIS (Internet Information Services) - created by Microsoft, tightly coupled to Windows, serves around 13% of the web

For this demo, we will be using Nginx because it's easy to set-up and incredibly flexible, also serving as a reverse proxy (sneak peak of what's to come).

The following commands should do the trick:

- `sudo apt update` to ensure that the package manager is up-to-date
- `sudo apt install nginx` to install nginx
- `sudo /etc/init.d/nginx start` to start the server

You can then go to `http://localhost` and you should see the default `Welome to ngingx!` page! And if you find the ip address of your Raspberry Pi (eg by typing `ifconfig`) then you should be able to access it from your own machine by going to that IP in the browser.

The configuration for the server can be found at `/etc/nginx/nginx.conf` and `/etc/nginx/sites-available/default` contains the default settings for localhost, listening on port 80 and returning the file at `/var/www/html/index.nginx-debian.html`. This file is the entry point for your site and you can edit the contents to display whatever you like.

## Where can I find you? (Configuring DNS)

So we can now access our site from any device on the network by using the IP address of our Raspberry Pi. But an IP address isn't the most ergonomic way to reach a site - all of our keen badger enthusiasts aren't going to want to type that in every time they want to vote. Better would be a memorable name, like... `badger.lover`, right? So how do we make that happen?

We need to provide a mechanism to exchange that memorable name that a user enters into an IP address so their computers can know where to go to. We need DNS.

The Domain Name System is the address book of the internet, making sure each browser doesn't get lost. A huge web of dedicated, interlinked DNS servers help answer every query on the internet, receiving requests like "gnomelands.com?" and responding with "46.32.253.112".

You can go to your computer settings and view the DNS servers that you've got configured for your WiFi - you'll probably see an entry like `1.1.1.1` (Cloudflare's DNS server) or `8.8.8.8` (Google's DNS server).

So for our example, we need a way of telling each device in our local network that `badger.lover` can be found on this network and at what IP - we need a local DNS server.

DNSMasq is a simple, lightweight DNS server that will do this nicely. To get set-up:

- `sudo apt update && sudo apt upgrade` to ensure you have the latest package references and are fully up to date
- `sudo apt install dnsmasq` to install DNSMasq
- in `/etc/dnsmasq.conf` uncomment the `domain-needed` and `bogus-priv` lines - these prevent packets with malformed domain names and packets with private IP addresses from leaving your network
- in your `/etc/hosts` file, add a line at the bottom `192.168.100.100 badger.lover`, where the exact IP address should be replaced by that of your Raspberry Pi. The hosts file is used by the DNS server (and your browsers on your own machine) to convert domain searches to IP addresses. Here, we are saying that any queries for `badger.lover` should be answered with the IP address for your Pi, to reach the web server we set up earlier
- `sudo service dnsmasq restart` will restart the server to bring these changes into effect

You now need to tell your own machine that it should use this new DNS server. Go to your DNS server settings and add your Pi IP as the first option in the list, so that it is asked first.

Now go to your browser, type `http://badger.lover` and you should be greeted with a lovely page about badgers! Your machine is first going to your new DNS server to get the IP, querying that IP address and reaching the web server we set up in step 1 and receiving your lovely web page. Except... it's on http, not https. Yuck!

## Trust me, I _am_ me (creating SSL certificates)

The internet is moving away from the world of old, insecure HTTP sites towards HTTPS, an initiative driven in no small part by Google.

HTTPS is HTTP over TLS (Transport Layer Security), meaning that it is fully encrypted end-to-end. This encryption is achieved with SSL (Secure Sockets Layer) certificates. Each certificate contains a public key that enables a secure handshake to take place before any real communication between a client (your browser) and server. It goes (sort of) as follows:

- Client: hi, server! Let's talk
- Server: ok, but people might be listening - let's talk in code
- Client: ooo tricky, how can we agree on a code without someone hearing what we decide?
- Server: here's a box with an open lock on it, you put the code in there, close the lock and send it back to me. Then I can use the key to open it up when it arrives.
- Client: great idea! Here's the code-in-a-box. Now you've got the code, let's use it from now on.
- Server: wlkejf23iojfewooioiwaejf?
- Client: koijewf2903u0932i9evirj!!!

The box with an open lock on it in this over-stretched personification is a public key - part of an asymmetric key set. With this public key, data can be encrypted by anyone but it can only be decrypted by the person with the private key. In this case, that's the server.

This public key is contained within the SSL certificate for a site. The SSL certificate is installed on the web server and any time a client comes along, the web server can provide the certificate to the client during the handshake process in order to establish fully encrypted communication in a way that even if someone was listening in, they wouldn't be able to crack.

But what if you're actually talking securely to a devious hAXxoR who actually wants to steal your information? In addition to containing a public key, an SSL certificate is used to prove a site is who it says it is.

Each certificate is _digitally signed_ by a **Certificate Authority** (CA) - a company that specialises in signing certificates. But how we trust them? Because they hold their own certificate signed by a **Root Certificate Authority** (root CA) - an organisation that is trusted by the browsers to only endorse responsible CAs. This chain of signed notes is used to create a link of trust from the top authority down to each web site.

To acquire an SSL certificate you need to prove that you actually own the domain so you can't pretend to be, like, Facebook or something.

So, what does that mean for our internal little site - do we need to prove that we own `badger.lover` so we can get a signed certificate? To do that, we would need to buy the domain name and expose the site to the internet for the CA's to confirm it exists and we run it. Seems like a lot of work.

Instead, we can create our own root CA called _Certificates On Me_ (or something) and get all the devices on the network to agree that they trust this CA so that any certificates it signs will be accepted by the browsers.

There are quite a few steps involved in this, so best if I hand off to an [article I followed](https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/) to get this configured successfully. This will take you through the steps of:

- configuring your root CA and generating a root CA certificate, which you can do on your Raspberry Pi
- adding this root CA certificate to the trusted list on your own device
- generating certificates signed by this root CA for your website (e.g. `badger.lover`)

Once you have generated your site certificate, you need to install

## References

<span id="1">1</span> : https://digitalintheround.com/what-is-the-most-popular-web-server/
