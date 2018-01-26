# AnatomyShare is an iPhone / iPad application that promotes collaborative learning in the medical school gross anatomy dissection laboratory. 

I posted some of the code from AnatomyShare here for people to see since the real repository is private.

iOS application to be used as a collaborative, information-sharing tool in the gross anatomy lab for medical students at Robert Wood Johnson Medical School. 

## Students can use AntaomyShare to:
  1. Post anatomical photos from their cadaveric dissections to be shared with their classmates.
      1.1 Posts can be annotated (drawings and text can be added).
  2. Comment or like any post.
  3. Access all of their posts, posts they have commented on, and posts they have liked.
  4. Sort posted information by individual cadaver, anatomical region, or category.
  5. Search the database for posts of interest.

## Tools used to develop AnatomyShare:
  1. Firebase database, storage, and user authentication. 
  2. Firebase cloud functions are used for denormalization of post data, database maintenance, and sending automated emails as needed.
  3. Algolia search provides real-time searching of all posts so that students can easily locate the information they are looking for. 
  4. Xcode, TestFlight, and iTunes Connect. 


## Sample Video
For obvious reasons I am not using the real anatomical images.This is the debug version of the app which just has random 
pictures that I have taken.

![Alt Text](https://github.com/dtroupe18/AnatomyShareDemoCode/blob/master/SampleVideo.gif)


