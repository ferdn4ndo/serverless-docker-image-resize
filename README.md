# uServer-Serverless-Image-Resize

<p align="center">
  <img src="https://raw.githubusercontent.com/ferdn4ndo/userver-serverless-image-resize/master/static/userver-serverless-image-resize-logo.png" alt="uServer Serverless Image Resize" width="200px">
</p>

---

> Image resize on-the-fly using AWS Lambda function with Serverless and Node.js

A simple Serverless service for creating an image resize-on-the-fly function with AWS Lambda. For Sharp to work correctly it must be installed in the same environment the production is running in. Because AWS Lambda is running on Amazon Linux it must be installed on the same system.

For this purpose, we're using Docker to spin up a container, install the Serverless Framework and deploy the function from inside the container.

This service will deploy both the AWS Lambda function and AWS S3 bucket from where the images will be grabbed, resized and put back.

## Getting Started (Ubuntu-based Linux Systems)

These instructions will get you up and running. See deployment for notes on how to deploy the project on a live system.

#### Clone to your local machine

```bash
git clone https://github.com/ferdn4ndo/userver-serverless-image-resize.git
```

#### Change into the cloned dir

```bash
cd userver-serverless-image-resize
```

#### Install Docker and docker compose

Please follow the instructions available at [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

All dependencies are installed. Now, deployment is a breeze.

## Deployment

### Configure secrets

#### 1. `secrets.json`

The `deploy.sh` script will autogenerate this file. No need to touch it at all.

#### 2. `secrets.env`

Add your secret keys and configuration variables here.

```env
SLS_KEY=XXX
SLS_SECRET=YYY
STAGE=dev
REGION=us-east-1
BUCKET=images.your-domain.com
```

### Run Docker Compose

```bash
docker compose up --build
```

This will build the image, create a container, run the `deploy.sh` script inside the container and deploy all the resources.

The command line will log out the service endpoints and all info. What's important to note is the bucket name and URL you need to access your images. Check out [Usage](#usage).

## Usage

After the service has been deployed, you will receive a bucket endpoint. You will add a query parameter to tell it how to resize the image. The bucket will behave as a public website.

Let's upload an image so we have something to work with. The original images (yet to be resized) should be uploaded to the `images_original` subfolder.

```bash
aws s3 cp --acl public-read IMAGE_NAME.jpg s3://<BUCKET>/images_original
```

Then you will execute the lambda function to resize it. In this example. we will resize the `IMAGE_NAME.jpg` file to 1080 (width) x 720 (height) pixels.

```
https://<LAMBDA_ID>.execute-api.<REGION>.amazonaws.com/prod/resize?key=1080x720/IMAGE_NAME.jpg
```

**NOTE**: The `LAMBDA_ID` parameter is printed when the container is deploying the function. Consider this example:

```
userver-serverless-image-resize-deploy  | Deploying userver-serverless-image-resize-fn to stage prod (us-east-1)
userver-serverless-image-resize-deploy  | Tracing DISABLED for function "userver-serverless-image-resize-fn-prod-resize"
userver-serverless-image-resize-deploy  |
userver-serverless-image-resize-deploy  | ✔ Service deployed to stack userver-serverless-image-resize-fn-prod (55s)
userver-serverless-image-resize-deploy  |
userver-serverless-image-resize-deploy  | endpoint: GET - https://12345abcde.execute-api.us-east-1.amazonaws.com/prod/resize
userver-serverless-image-resize-deploy  | functions:
userver-serverless-image-resize-deploy  |   resize: userver-serverless-image-resize-fn-prod-resize (9 MB)
```

In this case, the `LAMBDA_ID` parameter value is `12345abcde` (fictional, of course).

After you request the lambda URL and the image resizing process finishes, you'll be redirected to the final image path:

```
http://<BUCKET>.s3-website.<REGION>.amazonaws.com/images_resized/1080x720/IMAGE_NAME.jpg
```

And this is the final public URL of the resized image, ready to be distributed in the new dimensions.

Or you can access the lambda function directly.

## Credits

This repository was forked from [serverless-docker-image-resize](https://github.com/adnanrahic/serverless-docker-image-resize) by [adnanrahic](https://github.com/adnanrahic).

The original tutorial for resizing S3 images I followed can be found [here](https://aws.amazon.com/blogs/compute/resize-images-on-the-fly-with-amazon-s3-aws-lambda-and-amazon-api-gateway/)!
