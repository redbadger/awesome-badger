# David Laban

## Open Source Projects

Most of my open source contributions happen on [GitHub](https://github.com/alsuren/) and are tracked on [Trello](https://trello.com/b/oUj099Rh/oss-contributions-and-other-projects), with a [WIP limit](https://kanbanize.com/kanban-resources/getting-started/what-is-wip) to stop myself going insane.

Highlights include:

- [mijia-homie](https://github.com/alsuren/mijia-homie/) - A home monitoring project which feeds temperature and humidity readings to Grafana.
  - This also spawned [bluez-async](https://github.com/bluez-rs/bluez-async - A BlueZ helper library which is useful in its own right.
- [hoverkite](https://github.com/hoverkite/hoverkite) - A project to fly a kite using hoverboard motors.
- [cargo-quickinstall](https://github.com/alsuren/cargo-quickinstall/) - A wrapper around `cargo install` that can fetch prebuilt executables to speed things up.
  - The eventual aim is to make a `cargo quickbuild` command that wraps `cargo build`, and can bootstrap your dependency tree with prebuilt assets on first build. This is a bit of a moon-shot though. Progress is tracked in the [cargo-quick](https://github.com/cargo-quick/) organization.

## Presentations

I've been using [remark](https://github.com/gnab/remark) [excalidraw](https://excalidraw.com/) (specifically my [embed-all-the-things branch](https://excalidraw-git-fork-alsuren-embed-font-excalidraw.vercel.app/)) and `npx live-server` for writing my presentations recently. I quite like the workflow. So far, I have written internal presentations about:

- Some internal presentations.
- [My home monitoring project](https://alsuren.github.io/mijia-homie/docs/presentation/) for Binary Solo, and updated for Rust London.

## Writing

### [Infrastructure Musings](./infrastructure-musings/README.md)

Jun 2021

Semi-structured musings about what my vision of infrastructure nirvana is, and what's available at the moment to help us on our way there.

### [Dapr Impressions](./dapr-impressions/README.md)

Jun 2021

Early impressions on dapr, its tooling, and how it fits into the universe.
