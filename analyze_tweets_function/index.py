"""
Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

This code is intended to be deployed as an AWS lambda for analyzing Tweets.
It receives an event when an S3 object is created by an Amazon Kinesis Firehose stream.
It labels the tweets in the S3 object using Amazon Comprehend and Amazon Rekognition.

API Triggers: SageMaker Ground Truth
Services: Amazon S3, Amazon Kinesis Data Firehose, Amazon Comprehend, Amazon Rekognition
Python 3.7 - AWS Lambda - Last Modified 8/27/19
"""

import boto3
import json
import re
import os
import urllib.request


# Boto3 Clients
s3 = boto3.resource('s3')
s3client = boto3.client('s3')
comprehend = boto3.client('comprehend')
firehose = boto3.client('firehose')
rekognition = boto3.client('rekognition')

# Global Vars
sentiment_stream = os.environ.get('SENTIMENT_STREAM', '')
entity_stream = os.environ.get('ENTITY_STREAM', '')
rekognition_stream = os.environ.get('REKOGNITION_STREAM', '')
s3_bucket = os.environ.get('BUCKET', '')
imagekey_prefix = os.environ.get('IMAGEKEY_PREFIX', 'tmp/')
min_label_confidence = float(os.environ.get('MIN_LABEL_CONFIDENCE', 50.0))
max_labels = int(os.environ.get('MAX_LABELS', 100))


def label_image(s3_bucket, image_s3_key, max_labels=max_labels, min_label_confidence=min_label_confidence):
    """
    Label and image stored in S3 using Amazon Rekognition. First calls the Detect Labels APi to get general-purpose labels.
    If 'Text' was detected the Detect Text API is called.
    If a 'Person' was detected the Detect Faces and Recognize Celebrity APIs are called.
    The Detect Moderation Labels API is always called.

    Results from each API are bundled into a dict object and returned along with the S3 path to the image
    """
    # Rekognition API Parameters
    image = {
        'S3Object': {
            'Bucket': s3_bucket,
            'Name': image_s3_key
        }
    }

    try:
        labels = rekognition.detect_labels(Image=image,
                                           MaxLabels=max_labels,
                                           MinConfidence=min_label_confidence)

        # Determine the need to run Detect Text, Recognize Celebrities, or Detect Faces APIs based on labels detected in image
        labelNames = {label['Name'] for label in labels['Labels']}
        if 'Text' in labelNames:
            text = rekognition.detect_text(Image=image)
        else:
            text = {}
        if 'Person' in labelNames:
            celebrities = rekognition.recognize_celebrities(Image=image)
            faces = rekognition.detect_faces(Image=image, Attributes=['ALL'])
        else:
            celebrities = {}
            faces = {}
        # Every image is run through moderation label detection
        moderation = rekognition.detect_moderation_labels(Image=image)
        # Bundle all labels together
        item = {
            'Labels': labels.get('Labels', []),
            'TextDetections': text.get('TextDetections', []),
            'CelebrityRecognition': {
                'UnrecognizedFaces': celebrities.get('UnrecognizedFaces', []),
                'CelebrityFaces': celebrities.get('CelebrityFaces', []),
                'OrientationCorrection': celebrities.get('OrientationCorrection', [])
            },
            'FaceDetails': faces.get('FaceDetails', []),
            'ModerationLabels': moderation.get('ModerationLabels',[])
        }
        print ('Processed: s3://{bucket}/{key}'.format(bucket=s3_bucket, key=image_s3_key))
        return (item, 's3://{bucket}/{key}'.format(bucket=s3_bucket, key=image_s3_key))
    except Exception as e:
        print('Failed to analyze image: {image} {error}'.format(image=json.dumps(image), error=str(e)))
        return (None, None)


def store_tweet_image_in_s3(image_url, s3_bucket=s3_bucket):
    """
    This function extracts an image path from a twitter image and loads the image to an S3 bucket with the path as the S3 object key.
    EXAMPLE URL: https://pbs.twimg.com/media/<MEDIAHASH>.png

    Returns the S3 bucket and object key of the image
    """

    image_reg = r".*\/(?P<mediahash>[^\.]*)\.(?P<ext>[^\.]{3})"
    image_match = re.match(image_reg, image_url)
    image_path = image_match.group('mediahash') + '.' + image_match.group('ext')
    image_fullpath = '/tmp/' + image_path

    # Catch image extensions Rekognition does not support
    if not image_match.group('ext') in ('jpg', 'png'):
        return (None, None)
    image_s3_key = imagekey_prefix + image_path

    # Download and image once and only once
    bucket = s3.Bucket(s3_bucket)
    objs = list(bucket.objects.filter(Prefix=image_s3_key))
    if len(objs) == 0:
        # Download Image
        try:
            urllib.request.urlretrieve(image_url, image_fullpath)
        except Exception as e:
            print('Failed to analyze image: {image} {error}'.format(image=image_url, error=str(e)))
            return (None, None)
        # Upload Image to S3
        s3client.upload_file(image_fullpath, s3_bucket, image_s3_key)
        # Remove Local Copy of Image
        os.remove(image_fullpath)
    return (s3_bucket, image_s3_key)


def analyze_tweet(tweet_json):
    tweet = json.loads(tweet_json)

    # Comprehend API Parameters
    tweet_text = tweet['text']
    language_code = 'en'

    # Comprehend Sentiment Detection
    sentiment = comprehend.detect_sentiment(Text = tweet_text, LanguageCode = language_code)
    # If valid response pass to firehose
    if sentiment['ResponseMetadata']['HTTPStatusCode'] == 200:
        sentiment_record = {
            'tweetid': tweet['id'], 'text': tweet_text,
            'sentiment': sentiment['Sentiment'],
            'sentimentPosScore': sentiment['SentimentScore']['Positive'],
            'sentimentNegScore': sentiment['SentimentScore']['Negative'],
            'sentimentNeuScore': sentiment['SentimentScore']['Neutral'],
            'sentimentMixedScore': sentiment['SentimentScore']['Mixed']
        }
        firehose.put_record(DeliveryStreamName=sentiment_stream, Record= { 'Data' :json.dumps(sentiment_record) + '\n'})

    # Comprehend Entity Detection
    entities = comprehend.detect_entities(Text=tweet_text, LanguageCode=language_code)
    # If valid response pass to firehose
    if entities['ResponseMetadata']['HTTPStatusCode'] == 200:
        for entity in entities['Entities']:
            entity_record = {
                'tweetid': tweet['id'],
                'text': tweet_text,
                'entity': entity['Text'],
                'type': entity['Type'],
                'score': entity['Score']
            }
            firehose.put_record(DeliveryStreamName=entity_stream, Record= { 'Data' : json.dumps(entity_record) + '\n'} )

    # Use Amazon Rekognition to analyze images in the tweet
    if tweet.get('extended_entities'):
       for media in tweet['extended_entities']['media']:
           if media['type'] == 'photo':
            s3_bucket, image_s3_key = store_tweet_image_in_s3(media['media_url'])
            # If the image was fetched, label using Amazon Rekognition
            if image_s3_key is not None and s3_bucket is not None:
                image_labels, s3image = label_image(s3_bucket, image_s3_key)
                if image_labels is not None and len(image_labels) > 0:
                    image_rekognition_record = {
                        'tweetid': tweet['id'],
                        'text': tweet_text,
                        'mediaid': media['id'],
                        'media_url': media['media_url'],
                        'image_labels': image_labels
                    }
                    firehose.put_record(DeliveryStreamName=rekognition_stream, Record= { 'Data' :json.dumps(image_rekognition_record) + '\n'})


def handler(event, context):
    # Download tweets from S3, analyze them using Amazon Comprehend and Amazon Rekognition, and send the results to Firehose
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    tweets_file = '/tmp/tweets.json'
    s3client.download_file(bucket, key, tweets_file)
    with open(tweets_file) as f:
        for tweet_json in f:
            analyze_tweet(tweet_json)
