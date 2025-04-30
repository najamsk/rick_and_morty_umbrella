# RickMorty Umbrella
This is an [Elixir](https://elixir-lang.org/) and [Phoenix/LiveView](https://phoenixframework.org/) app based on an Elixir umbrella project. Kudos to [Rick and Morty API](https://rickandmortyapi.com/) for providing a wonderful API. On startup, this project loads data from the [Rick and Morty API](https://rickandmortyapi.com/) and stores textual data in a JSON file, which serves as our store, while images are downloaded as well.

<a href="https://www.buymeacoffee.com/najamsk" target="_blank">
<img
    src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png"
    alt="Buy Me A Coffee"
    style="height: 36px !important;width: 150px !important;"
/>
</a>

<a href="https://ko-fi.com/C0C71E7JQK" target="_blank"><img height="36" style="border:0px;height:36px;" src="https://storage.ko-fi.com/cdn/kofi2.png?v=6" border="0" alt="Buy Me a Coffee at ko-fi.com" /></a>

## API Project

Inside our umbrella project, the `Api` app is responsible for serving a simple REST API based on the `characters.json` file we compiled using the Rick and Morty API.

## FrontEnd Project

As the name suggests, it serves the UI to users with a characters list that can be filtered based on user input. Data is fetched from the `Api` project, and images are served from this project using the `images` folder and character IDs.

**TODO: Add description**

## Screenshots

![List Characters](readme/list.png "List Characters")  
![Details](readme/details.png "Details")

## Installation & Run

Clone the repo, then in your terminal, open the root of the project and run:

```bash
mix deps.get
```

To run the frontend and API from the root, execute the following:

```bash
iex -S mix phx.server
```

<a href="https://ko-fi.com/C0C71E7JQK" target="_blank"><img height="36" style="border:0px;height:36px;" src="https://storage.ko-fi.com/cdn/kofi2.png?v=6" border="0" alt="Buy Me a Coffee at ko-fi.com" /></a>
