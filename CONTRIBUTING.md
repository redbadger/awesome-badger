# Contributing

Awesome Badger is meant to be a place for _anyone_ at Red Badger (or even outside) to publish their thoughts. The focus is on technology, but if you want to write about something else, you're absolutely welcome to.

The audience is intended to be technical and mostly internal, although the repo is public. There is no other goal than for the Red Badger tech community to share ideas and experiences with one another.

## 1: How it Works

The Awesome Badger blog site is formatted using GitHub Pages, which in turn uses Jekyll to transform your markdown files into formatted HTML Pages.

For brand consistency, a custom Jekyll theme has been created (based on the standard Minima theme) that wraps every blog post in a standard header and footer.  All the Red Badger branding information (social media links and contact email address etc) is included for you in these standard sections.

When you clone this repo, you will notice that there are various directories such as `_includes`, `_layouts` or `_sass`.<br>
99% of the time, you will not need to change any of the files in these directories, and even then, please do not do so unless you're familiar with Jekyll.

## 2: Adding Yourself as a Contributor (One-off Task)

If this is the first time you are contributing to the Awesome Badger blog site, please follow these initials steps:

1. Edit the file [`_config.yml`](_config.yml) and add your details to the `contributors` object.  There are several things to be aware of here:
   * The value of `user` must be your GitHub userid, and the value of `author` is your display name.
   * Jekyll does not sort this list, so please insert your details so that your name appears sorted alphabetically by surname.
   * Jekyll uses these values to identify you as the author of a blog post, and the same value will appear in the front matter of all your blog posts.
1. Using the same value you gave for `user` (your Github userid), create a top level directory and optionally, your own subdirectory under `/assets`.  (If you want your blogs to contain images and other non-markdown files, you'll need to put these files here)
1. Within your user folder, create a `README.md` file and write a description of yourself that includes things like your role at Red Badger, links to yourself on social media sites, what you do outside of work, etc etc.  Take a look at [Stu's profile][stu] as an example.

## 3: Create a Blog File

Since this website is generated using Jekyll, all blog posts need to follow these conventions:

1. All blog posts must be created in the `_posts` folder
1. All blog post files must be named according to the following convention:
   * The file name must start with the date in `YYYY-MM-DD` format
   * Within the filename, do not use the space character as a separator, use hyphens `-` instead
   * The filename must end in `.md`

  For example, let's says its Jan 4th, 2022 and you want to create a blog about the aerodynamic properties of rubber chickens (please try to contain your excitement).  Your blog filename will therefore need to start with the date followed by a meaningful description.  E.G. `2022-01-04-aerodynamics-of-rubber-chickens.md`

## 4: Write a Blog

### 4.1: Create the Front Matter

Once your blog file has been created, the first few lines of the file must contain the Jekyll front matter.  This is nothing more than a hyphen-delimited `---` section of the file in which various YAML key/value pairs are defined.  Here's an example:

```yaml
---
layout: post
title: "Guiding Principles for Agile Technology Choices"
date: 2020-07-20 12:00:00 +0000
redirect_from: /charypar/tech-principles/
categories: charypar
author: Victor Charypar
excerpt: An attempt to capture some guiding principles for making technology choices - picking tools, tech stacks and making architecture decisions.
---
```

The following fields are used:

| Field | Value | Description
|---|---|---
| `layout` | `post` | Mandatory value
| `title` | | The title used by Jekyll when generating the overview page
| `date` | `YYYY-MM-DD HH:MM:SS <timezone offset in minutes>` | The blog creation datestamp used by Jekyll to list your blogs in chronological order.<br>The exact value of the time part is only important if you have blogged more than once on the same day, but the date part ***must*** be the same as the date in the blog filename
| `redirect_from` | Old blog URL | Do ***not*** add this field if you are writing a new blog.<br>It is only needed to ensure that the old URLs of blogs posted before the site was rebranded continue to work
| `categories` | Github userid | This must be the same name you entered for the `contributors.user` field in `_config.yml`.<br>Normally Jekyll uses this value to categorise blog posts, but here we have hijacked it to hold the user name.  This value is then referenced by the `permalink` definition in `_config.yml`
| `author` | Your display name | This must be the same name you entered for the `contributors.author` field in `_config.yml`
| `excerpt` | | A brief description of the blog used on the overview page

If you understand how to use the Liquid scripting language, then you can add your own fields into the front matter and reference them in the blog body using the syntax `{{ page.<field_name> }}`.  For instance, if you want to display your own name, you would enter the script tag `{{ page.author }}`.  However, please be aware that these placeholders are only substituted after Jekyll has generated the Github Pages site.  When looking at markdown files directly in Github, any links containing such placeholders will be broken.

### 4.2: Write Your Blog Content

After the front matter section, write your blog content and format it using Git Flavored Markdown.

You will not need to give your blog a level one heading, because Jekyll will automatically add the page title for you when the page is rendered.

### 4.3: Non-Markdown Content (Images etc)

If your blog requires the use of images (or any other non-markdown file type) and don't already have one, using your Github userid as the name, please create your own directory under `/assets`.

For instance, many of [Chris'][chris] blogs contain references to file types such as images, JavaScript and WebAssembly Text. All of these are located in `/assets/chriswhealy`.

Beneath your `/assets` user directory, you are free to use any directory structure you like.

## 5. Get a Review

You can push straight to master if you want to, but it's probably a good idea to get someone to review your post.

Just create a new pull request (like you would in a software project) and get someone to take a look.  If you post a link to your pull request in the `dx` Slack Channel, this will notify people that you have just created a blog, and someone will take a look (probably... 😃)

## 6. Have fun

That's it, have fun writing and reading your fellow Badgers' posts!

## Other things you could do

In no particular order:

- If you've got post ideas or requests, you can open an issue suggesting them.
- Include working code alongside your writing, why not
- Add any sort of helpful automation you think is a good idea

[stu]: stuartharris/
[chris]: chriswhealy/
