# Flickr Slide Show

- Feature
Slide show app that can see images from [Flickr Public Feed](https://www.flickr.com/services/feeds/docs/photos_public/).
Even Internet connection is offline, Flickr Slide Show tries to stay calm and curate images from the past.

- TODOs
Current image downloading logic has some issues.
	1. Requesting image list from public feed can be called multiple times simultaneously. It should be called only once at the moment for efficiency.
	2. Instead of calling `imageWithMetaData` function every second, I'm considering subscribing to UIImage Observable. By using observable, I can remove nil checking logic and make robust declarative code.
