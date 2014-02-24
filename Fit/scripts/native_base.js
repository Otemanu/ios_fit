/**
 * Created with IntelliJ IDEA.
 * User: mike
 * Date: 11/20/13
 * Time: 3:59 PM
 * To change this template use File | Settings | File Templates.
 */

/**
 * Function that gets a quiz from the devices SQL Lite database,
 *
 * @param quizId the quiz ID that correlates to the ID of the quiz
 */
function loadQuizNative(quizId) {
    fetchJson(quizId);
}

/**
 * Will update or insert the question result object
 *
 * @param quizId
 * @param questionResult  (QuestionResult)
 */
function setSelectAnswer(quizId, questionResult) {
    setSelectAnswerDB(quizId, questionResult);
}

function setLastPageIndex(quizId, index) {
    setLastPageIndexDB(quizId, index)
}

function getLastPageIndex(quizId) {
    getLastPageIndexDB(quizId)
}

function setQuizSeconds(quizId, payload) {
    setQuizSecondsDB(quizId, payload)
}

function getQuizPastResult(quizId ){

    getQuizPastResultDB(quizId);
}



/**
 *
 * @param actionObject (ActionData) is of type action data
 */
function nativeAction(actionObject) {

    switch (actionObject.action) {

        case 'FetchQuizJson':
            //payload is NULL
            loadQuizNative(actionObject.quizId);
            break;

        case 'QuizPastResults':
            //payload is NULL
            getQuizPastResult(actionObject.quizId);
            break;

        case 'SelectAnswer':
            //payload is QuestionResult object
            setSelectAnswer(actionObject.quizId, actionObject.payload);
            break;

        case 'SetLastPageIndex':
            //payload is int
            setLastPageIndex(actionObject.quizId, actionObject.payload);
            break;

        case 'GetLastPageIndex':
            //payload is NULL
            getLastPageIndex(actionObject.quizId);
            break;

        case 'SetQuizSeconds':
            //payload is (int) seconds
            setQuizSeconds(actionObject.quizId, actionObject.payload);
            break;

        default :
            console.error("No handler for action=" + actionObject.action);

    }

}

