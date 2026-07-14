Submissions are evaluated on [area under the ROC curve](http://en.wikipedia.org/wiki/Receiver_operating_characteristic) between the predicted probability and the observed target.


## Submission File
For each `id` in the test set, you must predict a probability for the target `rainfall`. The file should contain a header and have the following format:

    id,rainfall
    2190,0.5
    2191,0.1
    2192,0.9
    etc.