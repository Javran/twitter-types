{-# LANGUAGE OverloadedStrings, DeriveDataTypeable #-}

module Web.Twitter.Types
       ( DateString
       , UserId
       , Friends
       , URIString
       , UserName
       , StatusId
       , LanguageCode
       , StreamingAPI(..)
       , Status(..)
       , SearchResult(..)
       , SearchStatus(..)
       , SearchMetadata(..)
       , RetweetedStatus(..)
       , DirectMessage(..)
       , EventTarget(..)
       , Event(..)
       , Delete(..)
       , User(..)
       , List(..)
       , Entities(..)
       , EntityIndices
       , Entity(..)
       , HashTagEntity(..)
       , UserEntity(..)
       , URLEntity(..)
       , MediaEntity(..)
       , MediaSize(..)
       , Coordinates(..)
       , Place(..)
       , BoundingBox(..)
       , checkError
       )
       where

import Data.Aeson
import Data.Aeson.Types (Parser)
import Data.Text (Text)
import Data.HashMap.Strict (HashMap)
import Control.Applicative
import Control.Monad

type DateString   = String
type UserId       = Integer
type Friends      = [UserId]
type URIString    = Text
type UserName     = Text
type StatusId     = Integer
type LanguageCode = String

data StreamingAPI = SStatus Status
                  | SRetweetedStatus RetweetedStatus
                  | SEvent Event
                  | SDelete Delete
                  -- -- | SScrubGeo ScrubGeo
                  | SFriends Friends
                  | SUnknown Value
                  deriving (Show, Eq)

checkError :: Object -> Parser ()
checkError o = do
    err <- o .:? "error"
    case err of
        Just msg -> fail msg
        Nothing -> return ()

instance FromJSON StreamingAPI where
    parseJSON v@(Object o) =
        SRetweetedStatus <$> js <|>
        SStatus <$> js <|>
        SEvent <$> js <|>
        SDelete <$> js <|>
        SFriends <$> (o .: "friends") <|>
        return (SUnknown v)
      where
        js :: FromJSON a => Parser a
        js = parseJSON v
    parseJSON _ = mzero

data Status =
    Status
    { statusCreatedAt          :: DateString
    , statusId                 :: StatusId
    , statusText               :: Text
    , statusSource             :: Text
    , statusTruncated          :: Bool
    , statusEntities           :: Maybe Entities
    , statusExtendedEntities   :: Maybe Entities
    , statusInReplyTo          :: Maybe StatusId
    , statusInReplyToUser      :: Maybe UserId
    , statusFavorite           :: Maybe Bool
    , statusRetweetCount       :: Maybe Integer
    , statusUser               :: User
    , statusRetweet            :: Maybe Status
    , statusPlace              :: Maybe Place
    , statusFavoriteCount      :: Integer
    , statusLang               :: Maybe Text
    , statusPossiblySensitive  :: Maybe Bool
    , statusCoordinates        :: Maybe Coordinates
    } deriving (Show, Eq)

instance FromJSON Status where
    parseJSON (Object o) = checkError o >>
        Status <$> o .:  "created_at"
               <*> o .:  "id"
               <*> o .:  "text"
               <*> o .:  "source"
               <*> o .:  "truncated"
               <*> o .:? "entities"
               <*> o .:? "extended_entities"
               <*> o .:? "in_reply_to_status_id"
               <*> o .:? "in_reply_to_user_id"
               <*> o .:? "favorited"
               <*> o .:? "retweet_count"
               <*> o .:  "user"
               <*> o .:? "retweeted_status"
               <*> o .:? "place"
               <*> o .:? "favorite_count" .!= 0
               <*> o .:? "lang"
               <*> o .:? "possibly_sensitive"
               <*> o .:? "coordinates"
    parseJSON _ = mzero

data SearchResult body =
    SearchResult
    { searchResultStatuses :: body
    , searchResultSearchMetadata :: SearchMetadata
    } deriving (Show, Eq)

instance FromJSON body =>
         FromJSON (SearchResult body) where
    parseJSON (Object o) = checkError o >>
        SearchResult <$> o .:  "statuses"
                     <*> o .:  "search_metadata"
    parseJSON _ = mzero

data SearchStatus =
    SearchStatus
    { searchStatusCreatedAt     :: DateString
    , searchStatusId            :: StatusId
    , searchStatusText          :: Text
    , searchStatusSource        :: Text
    , searchStatusUser          :: User
    , searchStatusCoordinates   :: Maybe Coordinates
    } deriving (Show, Eq)

instance FromJSON SearchStatus where
    parseJSON (Object o) = checkError o >>
        SearchStatus <$> o .:  "created_at"
                     <*> o .:  "id"
                     <*> o .:  "text"
                     <*> o .:  "source"
                     <*> o .:  "user"
                     <*> o .:? "coordinates"
    parseJSON _ = mzero

data SearchMetadata =
    SearchMetadata
    { searchMetadataMaxId         :: StatusId
    , searchMetadataSinceId       :: StatusId
    , searchMetadataRefreshUrl    :: URIString
    , searchMetadataNextResults   :: Maybe URIString
    , searchMetadataCount         :: Int
    , searchMetadataCompletedIn   :: Maybe Float
    , searchMetadataSinceIdStr    :: String
    , searchMetadataQuery         :: String
    , searchMetadataMaxIdStr      :: String
    } deriving (Show, Eq)

instance FromJSON SearchMetadata where
    parseJSON (Object o) = checkError o >>
        SearchMetadata <$> o .:  "max_id"
                       <*> o .:  "since_id"
                       <*> o .:  "refresh_url"
                       <*> o .:? "next_results"
                       <*> o .:  "count"
                       <*> o .:? "completed_in"
                       <*> o .:  "since_id_str"
                       <*> o .:  "query"
                       <*> o .:  "max_id_str"
    parseJSON _ = mzero

data RetweetedStatus =
    RetweetedStatus
    { rsCreatedAt       :: DateString
    , rsId              :: StatusId
    , rsText            :: Text
    , rsSource          :: Text
    , rsTruncated       :: Bool
    , rsEntities        :: Maybe Entities
    , rsUser            :: User
    , rsRetweetedStatus :: Status
    , rsCoordinates     :: Maybe Coordinates
    } deriving (Show, Eq)

instance FromJSON RetweetedStatus where
    parseJSON (Object o) = checkError o >>
        RetweetedStatus <$> o .:  "created_at"
                        <*> o .:  "id"
                        <*> o .:  "text"
                        <*> o .:  "source"
                        <*> o .:  "truncated"
                        <*> o .:? "entities"
                        <*> o .:  "user"
                        <*> o .:  "retweeted_status"
                        <*> o .:? "coordinates"
    parseJSON _ = mzero

data DirectMessage =
    DirectMessage
    { dmCreatedAt          :: DateString
    , dmSenderScreenName   :: Text
    , dmSender             :: User
    , dmText               :: Text
    , dmRecipientScreeName :: Text
    , dmId                 :: StatusId
    , dmRecipient          :: User
    , dmRecipientId        :: UserId
    , dmSenderId           :: UserId
    , dmCoordinates        :: Maybe Coordinates
    } deriving (Show, Eq)

instance FromJSON DirectMessage where
    parseJSON (Object o) = checkError o >>
        DirectMessage <$> o .:  "created_at"
                      <*> o .:  "sender_screen_name"
                      <*> o .:  "sender"
                      <*> o .:  "text"
                      <*> o .:  "recipient_screen_name"
                      <*> o .:  "id"
                      <*> o .:  "recipient"
                      <*> o .:  "recipient_id"
                      <*> o .:  "sender_id"
                      <*> o .:? "coordinates"
    parseJSON _ = mzero

data EventType = Favorite | Unfavorite
               | ListCreated | ListUpdated | ListMemberAdded
               | UserUpdate | Block | Unblock | Follow
               deriving (Show, Eq)

data EventTarget = ETUser User | ETStatus Status | ETList List | ETUnknown Value
                 deriving (Show, Eq)

instance FromJSON EventTarget where
    parseJSON v@(Object o) = checkError o >>
        ETUser <$> parseJSON v <|>
        ETStatus <$> parseJSON v <|>
        ETList <$> parseJSON v <|>
        return (ETUnknown v)
    parseJSON _ = mzero

data Event =
    Event
    { evCreatedAt       :: DateString
    , evTargetObject    :: Maybe EventTarget
    , evEvent           :: Text
    , evTarget          :: EventTarget
    , evSource          :: EventTarget
    } deriving (Show, Eq)

instance FromJSON Event where
    parseJSON (Object o) = checkError o >>
        Event <$> o .:  "created_at"
              <*> o .:? "target_object"
              <*> o .:  "event"
              <*> o .:  "target"
              <*> o .:  "source"
    parseJSON _ = mzero

data Delete =
    Delete
    { delId  :: StatusId
    , delUserId :: UserId
    } deriving (Show, Eq)

instance FromJSON Delete where
    parseJSON (Object o) = checkError o >> do
        s <- o .: "delete" >>= (.: "status")
        Delete <$> s .: "id"
               <*> s .: "user_id"
    parseJSON _ = mzero

data User = User
    { userContributorsEnabled :: Bool
    , userCreatedAt :: DateString
    , userDefaultProfile :: Bool
    , userDefaultProfileImage :: Bool
    , userDescription :: Maybe Text
    , userFavoritesCount :: Int
    , userFollowRequestSent :: Maybe Bool
    , userFollowing :: Maybe Bool
    , userFollowersCount :: Int
    , userFriendsCount :: Int
    , userGeoEnabled :: Bool
    , userId :: UserId
    , userIsTranslator :: Bool
    , userLang :: LanguageCode
    , userListedCount :: Int
    , userLocation :: Maybe Text
    , userName :: Text
    , userNotifications :: Maybe Bool
    , userProfileBackgroundColor :: Maybe Text
    , userProfileBackgroundImageURL :: Maybe URIString
    , userProfileBackgroundImageURLHttps :: Maybe URIString
    , userProfileBackgroundTile :: Maybe Bool
    , userProfileBannerURL :: Maybe URIString
    , userProfileImageURL :: Maybe URIString
    , userProfileImageURLHttps :: Maybe URIString
    , userProfileLinkColor :: Text
    , userProfileSidebarBorderColor :: Text
    , userProfileSidebarFillColor :: Text
    , userProfileTextColor :: Text
    , userProfileUseBackgroundImage :: Bool
    , userProtected :: Bool
    , userScreenName :: Text
    , userShowAllInlineMedia :: Maybe Bool
    , userStatusesCount :: Int
    , userTimeZone :: Maybe Text
    , userURL :: Maybe URIString
    , userUtcOffset :: Maybe Int
    , userVerified :: Bool
    , userWithheldInCountries :: Maybe Text
    , userWithheldScope :: Maybe Text
    } deriving (Show, Eq)

instance FromJSON User where
    parseJSON (Object o) = checkError o >>
        User <$> o .:  "contributors_enabled"
             <*> o .:  "created_at"
             <*> o .:  "default_profile"
             <*> o .:  "default_profile_image"
             <*> o .:? "description"
             <*> o .:  "favourites_count"
             <*> o .:? "follow_request_sent"
             <*> o .:? "following"
             <*> o .:  "followers_count"
             <*> o .:  "friends_count"
             <*> o .:  "geo_enabled"
             <*> o .:  "id"
             <*> o .:  "is_translator"
             <*> o .:  "lang"
             <*> o .:  "listed_count"
             <*> o .:? "location"
             <*> o .:  "name"
             <*> o .:? "notifications"
             <*> o .:? "profile_background_color"
             <*> o .:? "profile_background_image_url"
             <*> o .:? "profile_background_image_url_https"
             <*> o .:? "profile_background_tile"
             <*> o .:? "profile_banner_url"
             <*> o .:? "profile_image_url"
             <*> o .:? "profile_image_url_https"
             <*> o .:  "profile_link_color"
             <*> o .:  "profile_sidebar_border_color"
             <*> o .:  "profile_sidebar_fill_color"
             <*> o .:  "profile_text_color"
             <*> o .:  "profile_use_background_image"
             <*> o .:  "protected"
             <*> o .:  "screen_name"
             <*> o .:? "show_all_inline_media"
             <*> o .:  "statuses_count"
             <*> o .:? "time_zone"
             <*> o .:? "url"
             <*> o .:? "utc_offset"
             <*> o .:  "verified"
             <*> o .:? "withheld_in_countries"
             <*> o .:? "withheld_scope"
    parseJSON _ = mzero

data List =
    List
    { listId :: Int
    , listName :: Text
    , listFullName :: Text
    , listMemberCount :: Int
    , listSubscriberCount :: Int
    , listMode :: Text
    , listUser :: User
    } deriving (Show, Eq)

instance FromJSON List where
    parseJSON (Object o) = checkError o >>
        List <$> o .:  "id"
             <*> o .:  "name"
             <*> o .:  "full_name"
             <*> o .:  "member_count"
             <*> o .:  "subscriber_count"
             <*> o .:  "mode"
             <*> o .:  "user"
    parseJSON _ = mzero

data HashTagEntity =
    HashTagEntity
    { hashTagText :: Text -- ^ The Hashtag text
    } deriving (Show, Eq)

instance FromJSON HashTagEntity where
    parseJSON (Object o) =
        HashTagEntity <$> o .: "text"
    parseJSON _ = mzero

data UserEntity =
    UserEntity
    { userEntityUserId              :: UserId
    , userEntityUserName            :: UserName
    , userEntityUserScreenName      :: Text
    } deriving (Show, Eq)

instance FromJSON UserEntity where
    parseJSON (Object o) =
        UserEntity <$> o .:  "id"
                   <*> o .:  "name"
                   <*> o .:  "screen_name"
    parseJSON _ = mzero

data URLEntity =
    URLEntity
    { ueURL      :: URIString -- ^ The URL that was extracted
    , ueExpanded :: URIString -- ^ The fully resolved URL (only for t.co links)
    , ueDisplay  :: Text    -- ^ Not a URL but a string to display instead of the URL (only for t.co links)
    } deriving (Show, Eq)

instance FromJSON URLEntity where
    parseJSON (Object o) =
        URLEntity <$> o .:  "url"
                  <*> o .:  "expanded_url"
                  <*> o .:  "display_url"
    parseJSON _ = mzero

data MediaEntity =
    MediaEntity
    { meType :: Text
    , meId :: StatusId
    , meSizes :: HashMap Text MediaSize
    , meMediaURL :: URIString
    , meMediaURLHttps :: URIString
    , meURL :: URLEntity
    } deriving (Show, Eq)

instance FromJSON MediaEntity where
    parseJSON v@(Object o) =
        MediaEntity <$> o .: "type"
                    <*> o .: "id"
                    <*> o .: "sizes"
                    <*> o .: "media_url"
                    <*> o .: "media_url_https"
                    <*> parseJSON v
    parseJSON _ = mzero

data MediaSize =
    MediaSize
    { msWidth :: Int
    , msHeight :: Int
    , msResize :: Text
    } deriving (Show, Eq)

instance FromJSON MediaSize where
    parseJSON (Object o) =
        MediaSize <$> o .: "w"
                  <*> o .: "h"
                  <*> o .: "resize"
    parseJSON _ = mzero

data Coordinates =
    Coordinates
    { coordinates :: [Double]
    , coordinatesType :: Text
    } deriving (Show, Eq)

instance FromJSON Coordinates where
    parseJSON (Object o) =
        Coordinates <$> o .: "coordinates"
                    <*> o .: "type"
    parseJSON _ = mzero

data Place =
    Place
    { placeAttributes   :: HashMap Text Text
    , placeBoundingBox  :: BoundingBox
    , placeCountry      :: Text
    , placeCountryCode  :: Text
    , placeFullName     :: Text
    , placeId           :: Text
    , placeName         :: Text
    , placeType         :: Text
    , placeUrl          :: Text
    } deriving (Show, Eq)

instance FromJSON Place where
    parseJSON (Object o) =
        Place <$> o .: "attributes"
              <*> o .: "bounding_box"
              <*> o .: "country"
              <*> o .: "country_code"
              <*> o .: "full_name"
              <*> o .: "id"
              <*> o .: "name"
              <*> o .: "place_type"
              <*> o .: "url"
    parseJSON _ = mzero

data BoundingBox =
    BoundingBox
    { boundingBoxCoordinates  :: [[[Double]]]
    , boundingBoxType         :: Text
    } deriving (Show, Eq)

instance FromJSON BoundingBox where
    parseJSON (Object o) =
        BoundingBox <$> o .: "coordinates"
                    <*> o .: "type"
    parseJSON _ = mzero

-- | Entity handling.
data Entities =
    Entities
    { enHashTags     :: [Entity HashTagEntity]
    , enUserMentions :: [Entity UserEntity]
    , enURLs         :: [Entity URLEntity]
    , enMedia        :: [Entity MediaEntity]
    } deriving (Show, Eq)

instance FromJSON Entities where
    parseJSON (Object o) =
        Entities <$> o .:? "hashtags" .!= []
                 <*> o .:? "user_mentions" .!= []
                 <*> o .:? "urls" .!= []
                 <*> o .:? "media" .!= []
    parseJSON _ = mzero

-- | The character positions the Entity was extracted from
--
--   This is experimental implementation.
--   This may be replaced by more definite types.
type EntityIndices = [Int]

data Entity a =
    Entity
    { entityBody    :: a             -- ^ The detail information of the specific entity types (HashTag, URL, User)
    , entityIndices :: EntityIndices -- ^ The character positions the Entity was extracted from
    } deriving (Show, Eq)

instance FromJSON a => FromJSON (Entity a) where
    parseJSON v@(Object o) =
        Entity <$> parseJSON v
               <*> o .: "indices"
    parseJSON _ = mzero
