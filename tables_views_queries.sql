--
-- This file contains database create, table and view definitions, and sample queries
-- for the AWS ML Blog 'Exploring The Eye of the Customer on Social Media using Amazon Rekognition and Amazon Athena'
--
--
-- Create the Athena database
--
create database socialanalyticsblog;

-- IMPORTANT: Replace <TwitterXxxLocation> in the 'LOCATION' parameter of each of the following SQL statements with the value shown as an output of the CloudFormation script

--
-- Table for Tweets
--
CREATE EXTERNAL TABLE socialanalyticsblog.tweets (
	coordinates STRUCT<
		type: STRING,
		coordinates: ARRAY<
			DOUBLE
		>
	>,
	retweeted BOOLEAN,
	source STRING,
	entities STRUCT<
		hashtags: ARRAY<
			STRUCT<
				text: STRING,
				indices: ARRAY<
					BIGINT
				>
			>
		>,
		urls: ARRAY<
			STRUCT<
				url: STRING,
				expanded_url: STRING,
				display_url: STRING,
				indices: ARRAY<
					BIGINT
				>
			>
		>
	>,
	reply_count BIGINT,
	favorite_count BIGINT,
	geo STRUCT<
		type: STRING,
		coordinates: ARRAY<
			DOUBLE
		>
	>,
	id_str STRING,
	timestamp_ms BIGINT,
	truncated BOOLEAN,
	text STRING,
	retweet_count BIGINT,
	id BIGINT,
	possibly_sensitive BOOLEAN,
	filter_level STRING,
	created_at STRING,
	place STRUCT<
		id: STRING,
		url: STRING,
		place_type: STRING,
		name: STRING,
		full_name: STRING,
		country_code: STRING,
		country: STRING,
		bounding_box: STRUCT<
			type: STRING,
			coordinates: ARRAY<
				ARRAY<
					ARRAY<
						FLOAT
					>
				>
			>
		>
	>,
    extended_entities struct<
        media:array<
            struct<
                id:string,
                indices: array<
                        bigint
                    >,
                media_url: string,
                media_url_https: string, url: string,
                display_url: string,
                expanded_url: string,
                type: string,
                sizes: struct<
                    thumb: struct<
                        w:int,
                        h:int,
                        resize:string
                    >,
                    large: struct <
                        w:int,
                        h:int,
                        resize: string
                    >,
                    medium: struct <
                        w:int,
                        h:int,
                        resize:string
                    >,
                    small: struct<
                        w:int,
                        h:int,
                        resize:string
                    >
                >
            >
        >,
        favorited: boolean,
        retweeted: boolean,
        possibly_sensitive: boolean,
        filter_level: string,
        lang: string
    >,
	favorited BOOLEAN,
	lang STRING,
	in_reply_to_screen_name STRING,
	is_quote_status BOOLEAN,
	in_reply_to_user_id_str STRING,
	user STRUCT<
		id: BIGINT,
		id_str: STRING,
		name: STRING,
		screen_name: STRING,
		location: STRING,
		url: STRING,
		description: STRING,
		translator_type: STRING,
		protected: BOOLEAN,
		verified: BOOLEAN,
		followers_count: BIGINT,
		friends_count: BIGINT,
		listed_count: BIGINT,
		favourites_count: BIGINT,
		statuses_count: BIGINT,
		created_at: STRING,
		utc_offset: BIGINT,
		time_zone: STRING,
		geo_enabled: BOOLEAN,
		lang: STRING,
		contributors_enabled: BOOLEAN,
		is_translator: BOOLEAN,
		profile_background_color: STRING,
		profile_background_image_url: STRING,
		profile_background_image_url_https: STRING,
		profile_background_tile: BOOLEAN,
		profile_link_color: STRING,
		profile_sidebar_border_color: STRING,
		profile_sidebar_fill_color: STRING,
		profile_text_color: STRING,
		profile_use_background_image: BOOLEAN,
		profile_image_url: STRING,
		profile_image_url_https: STRING,
		profile_banner_url: STRING,
		default_profile: BOOLEAN,
		default_profile_image: BOOLEAN
	>,
	quote_count BIGINT
) ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION '<TwitterRawLocation>';

--
-- Table for output of Amazon Comprehend detect_entities
--
CREATE EXTERNAL TABLE socialanalyticsblog.tweet_entities (
	tweetid BIGINT,
	entity STRING,
	type STRING,
	score DOUBLE
) ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION '<TwitterEntitiesLocation>';

--
-- Table for output of Amazon Comprehend detect_sentiments
--
CREATE EXTERNAL TABLE socialanalyticsblog.tweet_sentiments (
	tweetid BIGINT,
	text STRING,
	originalText STRING,
	sentiment STRING,
	sentimentPosScore DOUBLE,
	sentimentNegScore DOUBLE,
	sentimentNeuScore DOUBLE,
	sentimentMixedScore DOUBLE
) ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION '<TwitterSentimentLocation>';

--
-- Output of Amazon Rekognition
--
CREATE EXTERNAL TABLE socialanalyticsblog.`media_rekognition` (
  `image_labels` struct<
	labels:array<struct<
		instances:array<struct<
			boundingbox:struct<
				width:double,
				top:double,
				left:double,
				height:double
				>,
			confidence:double
				>>,
		confidence:double,
		parents:array<struct<
			name:string
			>>,
		name:string
		>>,
	textdetections:array<struct<
		geometry:struct<
			boundingbox:struct<
				width:double,
				top:double,
				left:double,
				height:double
				>,
			polygon:array<struct<
				x:double,
				y:double
				>>
			>,
		confidence:double,
		detectedtext:string,
		type:string,
		id:int,
		parentid:int
		>>,
	facedetails:array<struct<
		confidence:double,
		eyeglasses:struct<
			confidence:double,
			value:boolean
			>,
		sunglasses:struct<
			confidence:double,
			value:boolean
			>,
		gender:struct<
			confidence:double,
			value:string
			>,
		landmarks:array<struct<
			x:double,
			y:double,
			type:string
			>>,
		pose:struct<
			yaw:double,
			roll:double,
			pitch:double>,
		emotions:array<struct<
			confidence:double,
			type:string
			>>,
		agerange:struct<
			high:int,
			low:int
			>,
		eyesopen:struct<
			confidence:double,
			value:boolean
			>,
		boundingbox:struct<
			width:double,
			top:double,
			left:double,
			height:double
			>,
		smile:struct<
			confidence:double,
			value:boolean
			>,
		mouthopen:struct<
			confidence:double,
			value:boolean
			>,
		quality:struct<
			sharpness:double,
			brightness:double
			>,
		mustache:struct<
			confidence:double,
			value:boolean
			>,
		beard:struct<
			confidence:double,
			value:boolean
			>
		>>,
	celebrityrecognition:struct<
		unrecognizedfaces:array<struct<
			boundingbox:struct<
				width:double,
				top:double,
				left:double,
				height:double
				>,
			confidence:double,
			landmarks:array<struct<
				x:double,
				y:double,
				type:string
				>>,
			pose:struct<
				yaw:double,
				roll:double,
				pitch:double
				>,
			quality:struct<
				sharpness:double,
				brightness:double
				>
			>>,
		celebrityfaces:array<struct<
			face:struct<
				boundingbox:struct<
					width:double,
					top:double,
					left:double,
					height:double
					>,
				confidence:double,
				landmarks:array<struct<
					x:double,
					y:double,
					type:string
					>>,
				pose:struct<
					yaw:double,
					roll:double,
					pitch:double
					>,
				quality:struct<
					sharpness:double,
					brightness:double
					>
				>,
				urls:array<string>,
				name:string,
				id:string,
				matchconfidence:double
				>
			>,
			orientationcorrection:string
			>,
		moderationlabels:array<struct<
				confidence:double,
				name:string,
				parentname:string
				>>,
				labelmodelversion:string
				>
				,
  `tweetid` bigint ,
  `mediaid` string ,
  `text` string ,
  `media_url` string )
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '<TwitterMediaLabelsLocation>';

--
-- Views
--

--
-- media_image_labels_query. Shows all the labels for each image
--
CREATE OR REPLACE VIEW media_image_labels_query AS
SELECT
  "tweetid"
, "mediaid"
, "media_url"
, "text"
, "label"."name" "label_name"
, "label"."parents" "label_parents"
FROM
  (
   SELECT *
   FROM
     media_rekognition
   , UNNEST("image_labels"."labels") t (label)
);

--
-- media_image_labels_face_query. Expose face details, for images with a label = 'Face'
--
CREATE OR REPLACE VIEW media_image_labels_face_query AS
SELECT
  "tweetid"
, "mediaid"
, "media_url"
, "text"
, "label"."name" "label_name"
, "label"."parents" "label_parents"
, "facedetails"."eyeglasses"."confidence" "eyeglasses_conf"
, "facedetails"."eyeglasses"."value" "eyeglasses_value"
, "facedetails"."sunglasses"."confidence" "sunglasses_conf"
, "facedetails"."sunglasses"."value" "sunglasses_value"
, "facedetails"."gender"."confidence" "gender_conf"
, "facedetails"."gender"."value" "gender_value"
, "facedetails"."agerange"."high" "age_range_high"
, "facedetails"."agerange"."low" "age_range_low"
, "facedetails"."smile"."value" "smiling"
, "facedetails"."smile"."confidence" "smile_confidence"
, "facedetails"."boundingbox"."top" "face_top_edge"
, "facedetails"."boundingbox"."left" "face_left_edge"
, "reduce"("facedetails"."emotions", "element_at"("facedetails"."emotions", 1), ("s_emotion", "emotion") -> IF(("emotion"."confidence" > "s_emotion"."confidence"), "emotion", "s_emotion"), ("s") -> "s") "top_emotion"
, "facedetails"."pose"."yaw"
, "facedetails"."pose"."roll"
, "facedetails"."pose"."pitch"
FROM
  (
   SELECT *
   FROM
     media_rekognition
   , UNNEST("image_labels"."labels") t (label)
   , UNNEST("image_labels"."facedetails") t (facedetails)
)
WHERE ("label"."name" = 'Face');

--
-- celeb_view: Expose details for any celebrities found in the image
--
CREATE OR REPLACE VIEW celeb_view AS
SELECT
  "tweetid"
, "user"."id" "user_id"
, "user"."screen_name"
, "user"."name" "user_name"
, "mediaid"
, "media_url"
, "tweets"."text" "tweettext"
, "tweets"."retweeted"
, (CASE WHEN ("substr"("tweets"."text", 1, 2) = 'RT') THEN true ELSE false END) "isretweet"
, "from_unixtime"(("timestamp_ms" / 1000)) "ts"
, "celebrityface"."name"
, "celebrityface"."urls"
, "celebrityface"."id"
, "celebrityface"."matchconfidence"
FROM
  ((
   SELECT *
   FROM
     media_rekognition
   , UNNEST("image_labels"."celebrityrecognition"."celebrityfaces") t (celebrityface)
)
INNER JOIN tweets ON ("tweets"."id" = "tweetid"));

--
-- Sample queries
--

--
-- Speed and Buzz
--
-- 1. 10 Most linked to domains
SELECT lower(url_extract_host(url.expanded_url)) AS domain,
         count(*) AS count
FROM
    (SELECT *
    FROM socialanalyticsblog.tweets
    CROSS JOIN UNNEST (entities.urls) t (url))
GROUP BY  lower(url_extract_host(url.expanded_url))
ORDER BY  COUNT(*) DESC
LIMIT 10;

-- 2. Show the image ids, along with the first line of text (if any) in the image, and basic tweet info
SELECT tweetid,
         user_name,
         media_url,
         element_at(textdetections,1).detectedtext AS first_line,
         expanded_url,
         tweet_urls.text
FROM
    (SELECT id,
         user.name AS user_name,
         text,
         entities,
         url.expanded_url as expanded_url
    FROM socialanalyticsblog.tweets
    CROSS JOIN UNNEST (entities.urls) t (url)) tweet_urls
JOIN
    (SELECT media_url,
         tweetid,
         image_labels.textdetections AS textdetections
    FROM socialanalyticsblog.media_rekognition) rk
    ON rk.tweetid = tweet_urls.id
WHERE lower(url_extract_host(expanded_url)) IN ('www.amazon.com', 'amazon.com', 'www.amazon.com.uk', 'amzn.to')
        AND NOT position('/dp/' IN url_extract_path(expanded_url)) = 0
LIMIT 50;

--
-- Labels and Faces
--

-- 1. What are the most frequently found labels in the images
SELECT label_name,
         count(*) AS count
FROM socialanalyticsblog.media_image_labels_query
GROUP BY label_name
ORDER BY 2 desc;

-- 2. Look at the top emotion for each face in each image
SELECT top_emotion.type AS emotion,
         top_emotion.confidence AS emotion_confidence ,
         milfq.* ,   -- return all the fields from this view
         "user".id AS user_id ,
         "user".screen_name ,
         "user".name AS user_name ,
         url.expanded_url AS url
FROM socialanalyticsblog.media_image_labels_face_query milfq
INNER JOIN socialanalyticsblog.tweets
    ON "tweets".id = tweetid, UNNEST(entities.urls) t (url)
WHERE position('.amazon.' IN url.expanded_url) > 0;

-- 3. Top emotions across all people in all images
SELECT top_emotion.type AS emotion,
         count(*) AS "count"
FROM socialanalyticsblog.media_image_labels_face_query milfq
WHERE top_emotion.confidence > 50
GROUP BY top_emotion.type
ORDER BY 2 desc;

--
-- Celebrity queries
--

-- 1. Count top celebrities
SELECT name as celebrity,
         count(*) as count
FROM socialanalyticsblog.celeb_view
GROUP BY  name ORDER BY  count(*) desc;

-- Find the content with Jonas in either the tweet text, or the image
SELECT cv.media_url,
         count(*) AS count ,
         detectedtext
FROM socialanalyticsblog.celeb_view cv
LEFT JOIN      -- left join to catch cases with no text
    (SELECT tweetid,
         mediaid,
         textdetection.detectedtext AS detectedtext
    FROM socialanalyticsblog.media_rekognition , UNNEST(image_labels.textdetections) t (textdetection)
    WHERE (textdetection.type = 'LINE'
            AND textdetection.id = 0) -- get the first line of text
    ) mr
    ON ( cv.mediaid = mr.mediaid
        AND cv.tweetid = mr.tweetid )
WHERE ( ( NOT position('jonas' IN lower(tweettext)) = 0 ) -- Jonas IN text
        OR ( (NOT position('jonas' IN lower(name)) = 0) -- Jonas IN image
        AND matchconfidence > 75) )  -- with pretty good confidence
GROUP BY  cv.media_url, detectedtext
ORDER BY  count(*) DESC;

