var SELECT_TYPE = "Select";
var MULTIPLE_TYPE = "Multiple";
var FILL_IN_TYPE = "FillIn";
var IMAGE_TYPE = "Image";
var ORDER_TYPE = "Order";
var INFORMATION_TYPE = "Information";

var CORRECT = "Correct";


/**
 *
 * @param action  (String) the actions name
 * @param quizId  (int) the quizzes id
 * @param callback (function) optional call back to send results
 * @constructor
 */
window.ActionData = function (action, quizId) {
    this.action = action;
    this.quizId = quizId;
    this.timeStamp = new Date().getTime();

    this.payload = null;
};



window.QuestionResult = function (questionId, answerIds, isCorrect, isGraded) {
    this.questionId = questionId;
    this.answerIds = answerIds; // array
    this.isCorrect = isCorrect;
    this.isGraded = isGraded;
};

/////////////////// Quiz Answer ////////////////////////////////////

window.QuizAnswer = function (quizId, questionId, answerId) {
    this.quizId = quizId;
    this.questionId = questionId;
    this.answerId = answerId;
    this.answers = null;
};

/////////////////// QuestionType /////////////// /////////////////////

window.QuestionType = function (json) {
    this.type = json.type;
    // this.id = json.id;
    // this.resource = json.resource;
};

/////////////////// Answer ////////////////////////////////////

window.Answer = function (json) {
    if (json !== undefined && json !== null) {
        this.answerId = json.answerId;
        this.orderNum = json.orderNum;
        this.text = json.text;
        this.result = json.result;
        this.resource = json.resource;
        this.uri = json.uri;
    }
};

/////////////////// Question ////////////////////////////////////

window.Question = function (json) {
    this.text = json.text;
    this.questionId = json.questionId;
    this.answers = json.answers;
    this.questionType = json.questionType;
    this.orderNum = json.orderNum;
    this.questionOrderNum = json.questionOrderNum;
    this.resource = json.resource;
    this.answerBank = json.answerBank;
    this.uri = json.uri;

    this.solution = json.solution;

};

Question.prototype = {

    findAnswer: function (answerId) {
        for (var i = 0; i < this.answers.length; i++) {
            var answer = new Answer(this.answers[i]);

            if (answer.answerId == answerId) {
                return answer;
            }
        }

        return null; // no answer found
    }
};

/////////////////// Quiz ////////////////////////////////////
window.Quiz = function (json) {
    this.questions = json.questions;
    this.quizId = json.quizId;
    this.name = json.name;
    this.lastPageIndex = json.lastPageIndex;

};

Quiz.prototype = {

    findQuestion: function (questionId) {
        for (var i = 0; i < this.questions.length; i++) {
            var question = new Question(this.questions[i]);

            if (question.questionId == questionId) {
                return question;
            }
        }

        console.error(" Cannot find question with questionId=" + questionId);
        return null; // no question found
    }
};

window.FillInBlanksSelectChecker = function (question) {
    this.question = question;
};

FillInBlanksSelectChecker.prototype = {

    decorateDiv: function (answer, isCorrect) {
        var element = document.getElementById('answer-fill-in-' + answer.answerId);

        if (isCorrect === undefined || isCorrect === null) {
            element.setAttribute('class', 'answer-fill-in');
            return;
        }

        if (isCorrect === true) {
            element.setAttribute('class', 'answer-fill-in-correct');
        } else {
            element.setAttribute('class', 'answer-fill-in-wrong');
        }

    },

    check: function (quizAnswerDb, updateDivs) {

        var associativeArray;

        if (useSqlLite) {
            associativeArray = toAssociativeArray(quizAnswerDb.answers);
        } else {
            associativeArray = quizAnswerDb.answers;
        }

        var correctCounter = 0;

        for (var index in associativeArray) {

            var userValue = associativeArray[index];
            var answerId = index.substring(index.indexOf("-") + 1);
            var answer = this.question.findAnswer(answerId);

            if (answer === null) {
                errorLogger("Cannot find answer with id=" + answerId);
                continue;
            }

            if (userValue === "") { // user left box blank
                if (updateDivs === true) {
                    this.decorateDiv(answer);
                }
            } else {
                if (answer.text == userValue) {
                    if (updateDivs === true) {
                        this.decorateDiv(answer, true);
                    }
                    correctCounter++;
                } else {
                    if (updateDivs === true) {
                        this.decorateDiv(answer, false);
                    }
                }
            } // we had a user value
        }//for

        return correctCounter == this.question.answers.length;
    }
};

///////////////////  MultipleSelectChecker ////////////////////////////////////
window.MultipleChoiceChecker = function (question) {
    this.question = question;
};

MultipleChoiceChecker.prototype = {
    check: function (answer) {

        if (answer === undefined || answer == null) {
            return false;
        }

        return (answer.result === CORRECT);
    }
};

///////////////////  MultipleSelectChecker ////////////////////////////////////
window.MultipleSelectChecker = function (question) {
    this.question = question;
};

MultipleSelectChecker.prototype = {
    check: function (quizAnswerDb) {

        console.log("MultipleSelectChecker.check(" + quizAnswerDb + ")");

        var dbResults = quizAnswerDb.answers;

        console.log("dbResults=" + dbResults);

        var dbArray = [];

        dbArray = dbResults;

        dbArray.sort();

        console.log("dbArray=" + dbArray);

        var answersToSelect = [];

        for (var i = 0; i < this.question.answers.length; i++) {
            var answer = new Answer(this.question.answers[i]);

            console.log("answer.result=" + answer.result);

            if (answer.result == CORRECT) {
                answersToSelect.push(answer.answerId + 0);
            }
        }

        answersToSelect.sort();

        console.log("answersToSelect=" + answersToSelect);

        return arraysIdentical(dbArray, answersToSelect);

    }
};

///////////////////  OrderAnswersChecker ////////////////////////////////////

window.OrderAnswersChecker = function (question) {
    this.question = question;
};

OrderAnswersChecker.prototype = {
    check: function (quizAnswerDb) {

        var dbResults = quizAnswerDb.answers;
        //console.log("dbResults=" + dbResults);

        var i;
        var array = [];

        for (i = 0; i < this.question.answers.length; i++) {
            var answer = new Answer(this.question.answers[i]);

            array[answer.result - 1] = answer.answerId;
        }

        var correctResults = fromArray(array);

        //console.log(" correctResults=" + correctResults);

        return dbResults == correctResults;

    }
};

///////// Array Util ////////////
function toAssociativeArray(commaList) {
    var temp = commaList.split(',');

    var r = [];

    for (var i = 0; i < temp.length; i++) {
        var idValue = temp[i].split(':');
        //console.log("idValue =" + idValue);

        r[idValue[0]] = idValue[1];

        //console.log("r[value] =" + r[idValue[0]]);
    }

    //console.log("r =" + r);

    return r;
}

function arraysIdentical(a, b) {
    var i = a.length;

    if (i != b.length) {
        return false;
    }

    while (i--) {
        if (a[i] !== b[i]) {
            return false;
        }
    }
    return true;
}

function fromArray(array) {
    var results = "";

    for (var i = 0; i < array.length; i++) {
        results += array[i];

        if (i + 1 < array.length) {
            results += ',';
        }
    }

    return results;
}

function fromAssociativeArray(array) {

    var results = "";

    for (var index in array) {
        results += index + ":" + array[index] + ",";
    }

    if (results.length > 0) {
        return results.substring(0, results.length - 1); //remove last comma
    }

    return results;
}

function toNumberArray(commaList) {
    var temp = commaList.split(',');
    var r = [];

    for (var i = 0; i < temp.length; i++) {
        r[i] = temp[i] - 0;
        // console.log("r[i]=" + r[i]);
    }

    return r;
}

function createArray(questionId) {
    var parent = document.getElementById('answers-' + questionId);

    var result = "";
    for (var i = 0; i < parent.children.length; i++) {
        var child = parent.children[i];
        result += getId(child.id);

        if (i + 1 < parent.children.length) {
            result += ',';
        }
    }

    return result;
}


