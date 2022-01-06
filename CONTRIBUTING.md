# Contributing

Awesome Badger is meant to be a place for _anyone_ at Red Badger (or even outside) to publish their thoughts. The focus is on technology, but if you want to write about something else, you're absolutely welcome to.

The audience is intended to be technical and mostly internal, although the repo is public. There is no other goal than for the Red Badger tech community to share ideas and experiences with one another.

## 1: How it Works

The Awesome Badger blog site is formatted using GitHub Pages, which in turn uses Jekyll to transform your markdown files into formatted HTML Pages.

For brand consistency, a custom Jekyll theme has been created (based on the standard Minima theme) that wraps every blog post in a standard header and footer.  All the Red Badger branding information (social media links and contact email address etc) is included for you in these standard sections.

When you clone this repo, you will notice that there are various directories such as `_includes`, `_layouts` or `_sass`.  99% of the time, you will not need to change any of the files in these directories, and even then, please do not do so unless you're familiar with Jekyll.

## 2: Adding Yourself as a Contributor (One-off Task)

If this is the first time you are contributing to the Awesome Badger blog site, please follow these initials steps:

1. Edit the file [`_config.yml`](_config.yml) and add your details to the `contributors` object.  There are several things to be aware of here:
   * The value of `user` must be your GitHub userid, and the value of `user_name` is your display name.
   * Jekyll does not sort this list, so please insert your details so that your name appears sorted alphabetically by surname.
   * Jekyll uses these values to identify you as the author of a blog post, and the same value will appear in the front matter of all your blog posts.
1. Using the same value you gave for `user` (your Github userid), create a top level directory
1. Within your user folder, create a `README.md` file and write a description of yourself that includes things like your role at Red Badger, links to yourself on social media sites, what you do outside of work, etc etc.  Take a look at [Stu's profile][stu] as an example.

### 3: Create a Blog File

Since this website is generated using Jekyll, all blog posts need to follow these conventions:

1. All blog posts must be created in the `_posts` folder
1. All blog post files must be named according to the following convention:
  * The file name must start with the date in `YYYY-MM-DD` format
  * Within the filename, do not use the space character as a separator, use hyphens `-` instead
  * The filename must end in `.md`

  For example, let's says its Jan 4th, 2022 and you want to create a blog about the aerodynamic properties of rubber chickens (please try to contain your excitement).  Your blog file will therefore need to be called `2022-01-04-aerodynamics-of-rubber-chickens.md`

## 4: Write a Blog

### 4.1: Create the Front Matter

Once your blog file has been created, the first few lines of the file must contain the Jekyll front matter.  This is nothing more than a hyphen-delimited `---` section of the file in which various YAML key/value pairs are defined.  Here's an example:

```yaml
---
layout: post
title: "Guiding Principles for Agile Technology Choices"
date: 2020-07-20 12:00:00 +0000
user: charypar
author: Victor Charypar
excerpt: An attempt to capture some guiding principles for making technology choices - picking tools, tech stacks and making architecture decisions.
---
```

Jekyll expects the following fields to be present:

| Field | Value
|---|---
| `layout` | Must be set to `post`
| `title` | The title used by Jekyll when generating the overview page
| `date` | The blog creation datestamp in the format `YYYY-MM-DD HH:MM:SS <Timezone offset in minutes>`.<br>Jekyll uses this datestamp to list your blogs in chronological order.  This means that the exact value of the time is only important if you have blogged more than once on the same day, but the date part ***must*** be the same as the date in the blog filename
| `user` | Your Github userid. This must match the name used to create your personal folder
| `author` | Your name
| `excerpt` | A brief description of the blog that appears on the overview page

If you understand how to use the Liquid scripting language, then you can add your own fields into the front matter and reference them in the blog body using the syntax `{{ page.<field_name> }}`.  For instance, if you want to display your own name, you would enter the script tag `{{ page.author }}`

### 4.2: Write Your Blog Content

After the front matter section, write your blog content and format it using Git Flavored Markdown.

### 4.3: Non-Markdown Content (Images etc)

All non-markdown content should be placed within your own directory within the top-level `assets` directory.

For instance, many of [Chris'][chris] blogs contain references to file types such as images, JavaScript and WebAssembly Text. All of these are located in `/assets/chriswhealy`.  Any time a reference is then needed from one of your blogs, you can simply link to `/assets/{{ page.user }}/<filename>`

## 5. Get a Review

You can push straight to master if you want to, but it's probably a good idea to get someone to review your post. Just open a pull request like you would in a software project and get someone to have a look.

## 6. Have fun

That's it, have fun writing and reading your fellow Badgers' posts!

## Other things you could do

In no particular order:

- If you've got post ideas or requests, you can open an issue suggesting them.
- Include working code alongside your writing, why not
- Add any sort of helpful automation you think is a good idea

[stu]: stuartharris/
[chris]: chriswhealy/
