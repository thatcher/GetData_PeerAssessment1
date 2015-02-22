# Homework assignment for Coursera getdata-011
# Week 3
# run_analysis.R
# 
# Does the following:
#
# 1. Merges the training and the test sets to create one data set.
# 2. Extracts only the measurements on the mean and standard deviation for each 
#    measurement. 
# 3. Uses descriptive activity names to name the activities in the data set.
# 4. Appropriately labels the data set with descriptive variable names. 
# 5. From the data set in [the last step], creates a second, independent tidy data set 
#    with the average of each variable for each activity and each subject.
#
#   My personal goal for this project is to stay very functional, minimal
#   and practical as opposed to including any higher abstraction.
#
# Chris Thatcher
library(data.table)

DATA_DIR = "UCI\ HAR\ Dataset/"
DATA_URL = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

FEATURES = "UCI\ HAR\ Dataset/features.txt"
LABELS = "UCI\ HAR\ Dataset/activity_labels.txt"

TRAIN_SUBJECTS = "UCI\ HAR\ Dataset/train/subject_train.txt"
TEST_SUBJECTS = "UCI\ HAR\ Dataset/test/subject_test.txt"

TRAIN_FEATURES = "UCI\ HAR\ Dataset/train/X_train.txt"
TEST_FEATURES = "UCI\ HAR\ Dataset/test/X_test.txt"

TRAIN_LABELS = "UCI\ HAR\ Dataset/train/y_train.txt"
TEST_LABELS = "UCI\ HAR\ Dataset/test/y_test.txt"

## Get the Data:
# Make sure we have the data to work with locally, otherwise go get it.
if( !file.exists(DATA_DIR) ){
    
    message("Extracting data from url.")
    
    data_zip = "temp.zip"
    
    if("Windows" == Sys.info()["sysname"])
        download.file(DATA_URL, destfile=data_zip)
    else
        download.file(DATA_URL, destfile=data_zip, method="curl")
    
    unzip(data_zip)
    file.remove(data_zip)
}

## Transform the Data:

# Step 1. Merges the training and the test sets to create one data set.
# Read in the training/testing features and join them into a single data set
# Hmmm, interesting memory error trying to use fread on the test/train data.
# It causes my RStudio to crash and seems to be related to this known issue:
#
#           https://github.com/Rdatatable/data.table/issues/796
#
# Instead we'll fall back to read.table, slower but works...
features = rbind(
    read.table( TRAIN_FEATURES, header=FALSE, colClasses=rep('numeric',561) ),
    read.table( TEST_FEATURES, header=FALSE, colClasses=rep('numeric',561) )
)

# 2. Extracts only the measurements on the mean and standard deviation for each 
# measurement. 
# 4. Appropriately labels the data set with descriptive variable names.
# Steps 2. & 4. are performed together to reduce operational steps.
# Read in the feature labels
feature_types = fread( FEATURES )
setnames(feature_types, c(1, 2), c('feature_id', 'feature_name'))

# --step 4: set the names for each column from the feature type file
setnames(features, feature_types$feature_id, feature_types$feature_name)

# --step 2: we are only interested in a small subset of columns related to mean and std
# measures of variables.
columns = grep('-mean\\(\\)|-std\\(\\)', feature_types$feature_name, perl=TRUE)
features = as.data.table(features[,columns])

# 3. Uses descriptive activity names to name the activities in the data set.
# Read in the activity labels
label_types = fread( LABELS )
setnames(label_types, c(1, 2), c('label_id', 'label_name'))

# Read in the training/testing labels, then add another column named 'activity'
# that maps the label_id to the human readable activity name
labels = rbind(fread( TRAIN_LABELS ), fread( TEST_LABELS ))
setnames(labels, c(1), c('label_id'))
labels[,activity:=label_types[label_id]$label_name]

# 5. From the data set in [the last step], creates a second, independent tidy data set 
# with the average of each variable for each activity and each subject.
# Read in the training/testing subject ids
subjects = rbind(fread( TRAIN_SUBJECTS ), fread( TEST_SUBJECTS ))
setnames(subjects, c(1), c('subject_id'))

# join the subject_id and human readable activity name for each row onto the
# data set in new columns
features[,activity:=labels$activity]
features[,subject:=subjects$subject_id]

# Find the mean of all columns aggregated by subject and activity
final = features[ ,lapply(.SD, mean), by=c('subject', 'activity')]

# Final step, write the tidy data
write.table(final, file='tidy_final.txt', row.names=FALSE)
