# Early impressions of NATS

_[David Laban](../) — June 2021_

NATS is a distributed queueing system.

## Protocol

NATS prides itself on its protocol's simplicity. It is a text based protocol with length-encoded payloads and a very small number of verbs, a bit like http 1.0. My first introduction to NATS was the keynote video on their website though (https://www.youtube.com/watch?v=lHQXEqyH57U), which talks about private keys and JWTs, so this initial simplicity feels like a trap.

## Reliability

> If the client reaches this internal limit, it will drop messages and continue to process new messages. This is aligned with NATS at most once delivery. It is up to your application to detect the missing messages and recover from this condition.

-- https://docs.nats.io/nats-server/nats_admin/slow_consumers

This is a different approach from other queueing systems that I have used. I am a little bit wary.

## Security

It's slightly concerning to find out that `--routes=nats://ruser:T0pS3cr3t@nats:6222` is baked into the default nats image. I wonder how many installations are running with that default exposed to the public internet. (I have heard that the security doesn't come from secrets stored in the cluster though, so this might not be important?)
