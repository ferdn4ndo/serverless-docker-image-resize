const stream = require('stream')
const AWS = require('aws-sdk')
const S3 = new AWS.S3({
  signatureVersion: 'v4'
})
const sharp = require('sharp')
const BUCKET = process.env.BUCKET
const URL = `http://${process.env.BUCKET}.s3-website.${process.env.REGION}.amazonaws.com`

const originalImagesFolder = "images_original/"
const resizedImagesFolder = "images_resized/"

// create the read stream abstraction for downloading data from S3
const readStreamFromS3 = ({ Bucket, Key }) => {
  return S3.getObject({ Bucket, Key }).createReadStream()
}
// create the write stream abstraction for uploading data to S3
const writeStreamToS3 = ({ Bucket, Key }) => {
  const pass = new stream.PassThrough()
  return {
    writeStream: pass,
    uploadFinished: S3.upload({
      Body: pass,
      Bucket,
      ContentType: 'image/png',
      Key
    }).promise()
  }
}
// sharp resize stream
const streamToSharp = ({ width, height }) => {
  return sharp()
    .resize(width, height)
    .toFormat('png')
}

exports.handler = async (event) => {
  const key = event.queryStringParameters.key
  const match = key.match(/(\d+)x(\d+)\/(.*)/)

  const width = parseInt(match[1], 10)
  const height = parseInt(match[2], 10)
  const originalFilename = match[3]
  const sizeSubfolder = '' + width + 'x' + height + '/'

  const originalKey = originalImagesFolder + originalFilename
  const newKey = resizedImagesFolder + sizeSubfolder + originalFilename

  const imageLocation = `${URL}/${newKey}`

  try {
    // create the read and write streams from and to S3 and the Sharp resize stream
    const readStream = readStreamFromS3({ Bucket: BUCKET, Key: originalKey })
    const resizeStream = streamToSharp({ width, height })
    const { writeStream, uploadFinished } = writeStreamToS3({ Bucket: BUCKET, Key: newKey })

    // trigger the stream
    readStream
      .pipe(resizeStream)
      .pipe(writeStream)

    // wait for the stream to finish
    const uploadedData = await uploadFinished

    // log data
    console.log('Data: ', {
      uploadedData: uploadedData,
      bucketUrl: URL,
      width: width,
      height: height,
      originalFilename: originalFilename,
      sizeSubfolder: sizeSubfolder,
      originalKey: originalKey,
      newKey: newKey,
      imageLocation: imageLocation,
    })

    // return a 301 redirect to the newly created resource in S3
    return {
      statusCode: '301',
      headers: { 'location': imageLocation },
      body: ''
    }
  } catch (err) {
    console.error(err)

    return {
      statusCode: '500',
      body: err.message
    }
  }
}
