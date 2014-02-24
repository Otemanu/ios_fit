function fetchJson(quizId) {
	var data = nativeFetchJson(quizId);
}

function setSelectAnswerDB(quizId, questionResult) {
    console.log("setSelectAnswerDB(quizId, questionResult)");

    var isCorrect = questionResult.isCorrect;
    var questionId = questionResult.questionId
    var questionResultJson = JSON.stringify(questionResult);

    console.log("questionResult=" + questionResult);
    console.log("questionResultJson=" + questionResultJson);
	nativeSetSelectAnswerDB(quizId, questionId, questionResultJson, isCorrect);

//    Android.setSelectAnswer(quizId, questionId, questionResultJson, isCorrect);

}

function setLastPageIndexDB(quizId, index) {
    console.log("setLastPageIndexDB(quizId, index)");

//    Android.setLastIndex(quizId, index);
}

function getLastPageIndexDB(quizId) {
    console.log("getLastPageIndexDB(quizId) ");

//    var last = Android.getLastIndex(quizId);
	var last = 0;
    generateQuestionsDiv(last); // callback to function in quiz.js

}

function getQuizPastResultDB(quizId) {
    console.log("getQuizPastResultDB(quizId) ");

//    var questionResults = Android.getQuizPastResults(quizId);

	var questionResults = "[]";
    var results = JSON.parse(questionResults);

    setQuestionResultsCallback(results); // callback to function in quiz.js
}

function setQuizSecondsDB(quizId, seconds) {
    console.log(" setQuizSecondsDB(quizId, payload)");
	NativeBridge.call("setQuizSecondsDB", [quizId, seconds], function (data) {
					  iOSCallbackWithJson(data);
					  });
}

function nativeFetchJson(quizId) {
	NativeBridge.call("fetchJson", quizId, function (data) {
					  iOSCallbackWithJson(data);
					  });
}

function nativeSetSelectAnswerDB(quizId, questionId, questionResultJson, isCorrect) {
	NativeBridge.call("setSelectAnswerDB", questionResultJson, function (data) {
					  iOSCallbackWithJson(data);
					  });
}

function iOSCallbackWithJson(data) {
	loadQuiz(data); // callback to function in quiz.js
}

