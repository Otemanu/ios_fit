var quiz;
var quizId = -1;
var slider = null;
var totalQuestions = 0;
//var answers = [];
//var currentPosition = 0;
var TOTAL_Q_DIVS = 3;
var questionResultsArray = [];

var currentIndex = 0;
var currentDisplayedQuestionIndex = 0;

var CORRECT_ICON = "icon-ok-circle";
var WRONG_ICON = "icon-remove-circle";
var SELECTED_ICON = "icon-circle-blank";

var start;

function getNowSeconds() {
    return  parseInt(Date.now() / 1000);
}

function loadDataInit(quizIdIn) {
    quizId = quizIdIn;

    if (quiz !== null && quiz !== undefined && quiz.quizId == quizId) {

        if (start == -1) {
            start = getNowSeconds();
        }
        return;
    } else {

        for (var i = 0; i < TOTAL_Q_DIVS; i++) {
            var element = document.getElementById('q' + i);
            element.innerHTML = "";
        }

        currentIndex = 0;
        currentDisplayedQuestionIndex = 0;
        questionResultsArray = [];
        quiz = null;

        start = getNowSeconds();

        console.log("start=" + start);

        if (slider != null) {
            mySwipe.slide(0);  // set to zero first slide
        }

        totalQuestions = 0;
    }

    var actionObject = new ActionData('FetchQuizJson', quizId);
    nativeAction(actionObject);
}

/**
 * Method that is called from web page
 * @param id (int) Quiz id
 */
function showQuiz(id) {

    document.getElementById("quiz-wrapper").style.display = 'block';

    loadDataInit(id);
}

/**
 * Loads the quiz from the string representing the Quiz object in json notation
 * @param jsonString Raw plain string
 */
function loadQuiz(jsonString) {

    console.log("jsonString.length=" + jsonString.length);

    if (jsonString !== undefined) {

        var json = JSON.parse(jsonString);

        if (json.hasOwnProperty("error")) {
            alert(json.error);

        } else {  // we don't have a property error
            quiz = new Quiz(json);

            getPastResults();

            //console.log("quiz=" + quiz.quizId + " quiz.questions.length=" + quiz.questions.length);
            generateQuiz();

            if (slider == null) {
                var elem = document.getElementById('mySwipe');
                window.mySwipe = Swipe(elem, {
                    //speed: 50,
                    continuous: true,
                    transitionEnd: function (index) {
                        slideCallBack(index);
                    }
                });

                slider = window.mySwipe;
            }

            //setAnswers();
        }

    } else {
        alert("Cannot find json for quiz with id=" + quizId);
    }
}

function computeAndSendQuizSeconds() {
    if (start != -1) {
        var totalSeconds = getNowSeconds() - start;
        start = -1;
        console.log("Closing window totalSeconds=" + totalSeconds);

        var actionObject = new ActionData('SetQuizSeconds', quizId);
        actionObject.payload = totalSeconds;

        nativeAction(actionObject);
    }  else {
        console.error("Start is " + start);
    }
}

function closeWindow() {

    computeAndSendQuizSeconds();

    //todo send to device we stopped
    //mobiSocket.close();
}

window.addEventListener("unload", closeWindow, false);

function loadAnsweredResults(questionResult) {

    selectAnswer(questionResult.questionId, questionResult.answerIds, false);

    if (questionResult.isGraded) {
        //console.log("GRADING");
        checkAnswer(questionResult.questionId, questionResult.answerIds, false);
    }
}

/*
 function loadPastResults(payload) {
 //console.log("payload=" + payload);

 var userDataList = JSON.parse(payload);

 //console.log(userDataList + "  userDataList=" + userDataList.length);

 for (var i = 0; i < userDataList.length; i++) {
 var data = userDataList[i];

 loadAnsweredResults(data);
 }

 setResultsMessage();
 }
 */
/*

 function setAnswerDataOtherDevice(payload) {
 var data = JSON.parse(payload);
 loadAnsweredResults(data);

 setResultsMessage();
 }
 */

/*
 function socketCallBack(data) {
 console.log("socketCallBack=");

 var obj = JSON.parse(data);

 var action = obj.action;

 if (action === "Start") {
 loadQuiz(obj.payload);
 } else if (action === "PastResults") {
 loadPastResults(obj.payload);
 } else if (action === "AnsweredOtherDevice") {
 setAnswerDataOtherDevice(obj.payload);
 }

 console.log("obj.action=" + obj.action);

 }
 */

/*
 function openCallBack(data) {
 //console.log("data=" + data);

 new QuizSessionClientCreator(5, quizId, sessionCreateCallBack)

 }
 */

/*
 function sessionCreateCallBack(quizSessionClientData) {
 //console.log("quizSessionClientData=" + quizSessionClientData);
 //mobiSocket.send(JSON.stringify(quizSessionClientData));
 }
 */

function sendLastIndexToWebSocket(index) {
    var actionObject = new ActionData('SetLastPageIndex', quizId);
    actionObject.payload = index;

    //console.log("Last Index index=" + index);

    nativeAction(actionObject);

    //mobiSocket.send(JSON.stringify(actionObject));
}

function getPastResults() {
    var actionObject = new ActionData('QuizPastResults', quizId);

    nativeAction(actionObject);

}

function isInformationType(question) {

    if (question == null) {
        return false;
    }

    var questionType = new QuestionType(question.questionType);
    return questionType.type == INFORMATION_TYPE;
}

function getTotalQuestions(questions) {

    if (totalQuestions === 0) {
        for (var i = 0; i < questions.length; i++) {
            var question = new Question(questions[i]);

            if (!isInformationType(question)) {
                totalQuestions++;
            }
        }
    }

    return totalQuestions;
}

function flipQuizWindow(questionId) {

    var front = document.getElementById('front-' + questionId);
    var back = document.getElementById('back-' + questionId);

    if (front.className.indexOf("flip") > -1) { // we have flip remove it
        front.className = "quiz-console-wrap front";
        back.className = "quiz-console-wrap back";

    } else {  // add flip
        front.className = "quiz-console-wrap front flip";
        back.className = "quiz-console-wrap back flip";
    }
}

function generateQuiz() {

    var actionObject = new ActionData('GetLastPageIndex', quizId);

    nativeAction(actionObject);
}

function generateQuizResults(divIn) {
    divIn.innerHTML = "";

    var parent = createTopParentSwipeDiv(null);
    var quizBody = parent.getElementsByClassName('quiz-body')[0];

    divIn.appendChild(parent);

    //var resultsListItem = document.createElement('li');
    var qQuestion = document.createElement('div');
    qQuestion.className = 'q-question';
    qQuestion.id = 'results-top';
    quizBody.appendChild(qQuestion);

    var resultsDivText = document.createElement('div');
    resultsDivText.className = 'results-text';
    resultsDivText.id = 'results-text';
    resultsDivText.innerHTML = "Results";
    qQuestion.appendChild(resultsDivText);

    var questionNum = 1;
    var question;

    var qAnswers = document.createElement('div');
    qAnswers.className = 'q-answers';
    quizBody.appendChild(qAnswers);

    for (var i = 0; i < quiz.questions.length; i++) {
        question = new Question(quiz.questions[i]);

        if (isInformationType(question)) {
            continue;
        }

        //todo do we show correct or incorrect if

        var resultDivItem = document.createElement('div');
        resultDivItem.className = 'answer';
        resultDivItem.id = 'results-div-' + question.questionId;
        resultDivItem.setAttribute('onclick', 'reVisitQuestion(' + question.orderNum + ')');

        var resultIcon = document.createElement('i');

        var questionResults = questionResultsArray[question.orderNum];

        if (questionResults === undefined || questionResults === null) {
            resultIcon.className = SELECTED_ICON;
        } else {
            if (questionResults.isCorrect) {
                resultIcon.className = CORRECT_ICON;
                resultDivItem.className = 'answer green';

            } else {
                resultIcon.className = WRONG_ICON;
                resultDivItem.className = 'answer red';
            }

            //questionResults.isGraded = true;
        }

        resultIcon.setAttribute('id', 'results-i-' + question.questionId);

        var resultSpanTextItem = document.createElement('span');
        resultSpanTextItem.id = 'resultsSpanText-' + question.questionId;
        resultSpanTextItem.innerHTML = "Question " + (questionNum++);

        qQuestion.appendChild(resultDivItem);

        resultDivItem.appendChild(resultIcon);
        resultDivItem.appendChild(resultSpanTextItem);

        qAnswers.appendChild(resultDivItem);
    }

    // divIn.appendChild(resultsListItem);

    // checkAndSetAllAnswers();

    setResultsMessage();
}

function setCorrectResultsOnResultsPage(question, isCorrect) {

    var resultsIDiv = document.getElementById('results-i-' + question.questionId);
    var resultsMainDiv = document.getElementById('results-div-' + question.questionId);

    if (resultsIDiv !== null && resultsMainDiv != null) {
        if (isCorrect === true) {
            resultsIDiv.className = CORRECT_ICON;
            resultsMainDiv.className = 'answer green';

        } else {
            resultsIDiv.className = WRONG_ICON;
            resultsMainDiv.className = 'answer red';
        }
    }

    setResultsMessage();
}

function setResultsMessage() {

    var element = document.getElementById('results-text');

    if (element == null) {
//        console.log("Cannot find results-text");

        return;
    }

    var correct = 0;

    for (var i = 0; i < questionResultsArray.length; i++) {
        if (questionResultsArray[i] !== undefined && questionResultsArray[i].isCorrect === true) {
            correct++;
        }
    }

    element.innerHTML = correct + " out of " + getTotalQuestions(quiz.questions) + " Answers Correct";
}

function checkAndSetAllAnswers() {

    for (var j = 0; j < quiz.questions.length; j++) {
        var question = new Question(quiz.questions[j]);

        if (isInformationType(question)) {
            continue;
        }

        checkAndSetAnswer(question);
    }

}

function checkAndSetAnswer(question) {

    var questionResult = questionResultsArray[question.orderNum];

    if (questionResult !== undefined && questionResult !== null) {

        questionResult.isGraded = true;

        //console.log("questionResult=" + questionResult);
        //console.log("question=" + question);

        var answer = question.findAnswer(questionResult.answerIds[0]);
        var result = check(question, answer);

        //setQuestionResultsCssClass(question, answer, result);
        setCorrectResultsOnResultsPage(question, result);
    }

}

function check(question, answer) {

    var questionType = new QuestionType(question.questionType);

    switch (questionType.type) {
        case SELECT_TYPE:
            var multipleChoiceChecker = new MultipleChoiceChecker(question);
            return multipleChoiceChecker.check(answer);

        case IMAGE_TYPE:
            console.error(IMAGE_TYPE + " IMPLEMENT");
            //TODO
            return false;

        case  MULTIPLE_TYPE :
            console.error(MULTIPLE_TYPE + " IMPLEMENT");
            //TODO
            return false;

        case ORDER_TYPE:
            console.error(ORDER_TYPE + " IMPLEMENT");
            //TODO
            return false;

        case FILL_IN_TYPE:
            console.error(FILL_IN_TYPE + " IMPLEMENT");
            //TODO
            return false;

        default:
            console.error(questionType.type + " No processor found  checkNoDbAnswer()");
            return false;
    }
}

function createQuizFooter() {

    var quizFooter = document.createElement('div');
    quizFooter.className = 'quiz-footer';

    /*** Left ***/
    var quizLeft = document.createElement('div');
    quizLeft.className = 'q-left';
    quizLeft.setAttribute('onclick', 'mySwipe.prev()');

    var iLeft = document.createElement('i');
    iLeft.className = 'icon-chevron-left';
    quizLeft.appendChild(iLeft);

    quizFooter.appendChild(quizLeft);

    /*** Right ***/
    var quizRight = document.createElement('div');
    quizRight.className = 'q-right';
    quizRight.setAttribute('onclick', 'mySwipe.next()');

    var iRight = document.createElement('i');
    iRight.className = 'icon-chevron-right';
    quizRight.appendChild(iRight);

    quizFooter.appendChild(quizRight);

    return quizFooter;
}

function createQuizHeader(question, flip) {
    var quizHeader = document.createElement('div');
    quizHeader.className = 'quiz-header';

    var questionNum = document.createElement('div');
    questionNum.className = 'q-num';

    var iQuit = document.createElement('i');
    iQuit.className = 'icon-remove-sign';
    iQuit.setAttribute('onclick', 'hideQuiz()');
    questionNum.appendChild(iQuit);

    var span = document.createElement('span');
    questionNum.appendChild(span);

    quizHeader.appendChild(questionNum);

    var quizHintToggle = document.createElement('div');
    quizHintToggle.className = 'q-switch';

    if (question !== undefined && question !== null) {
        quizHintToggle.setAttribute('onclick', 'flipQuizWindow(' + question.questionId + ')');
    }

    var aQuiz = document.createElement('a');

    if (!flip) {
        aQuiz.className = 'select';
    }

    aQuiz.innerHTML = 'Quiz';
    quizHintToggle.appendChild(aQuiz);

    var aHint = document.createElement('a');

    if (flip) {
        aHint.className = 'select';
    }

    aHint.innerHTML = 'Hint';
    quizHintToggle.appendChild(aHint);

    quizHeader.appendChild(quizHintToggle);

    if (question === null) {
        span.innerHTML = " Results";
        quizHintToggle.style.display = 'none';
    } else if (isInformationType(question)) {
        span.innerHTML = " Info";
        quizHintToggle.style.display = 'none';
    } else {
        span.innerHTML = ' ' + question.questionOrderNum + ' of ' + getTotalQuestions(quiz.questions);

        if (question.solution === undefined || question.solution === null || question.solution.length == 0) {
            quizHintToggle.style.display = 'none';
        }

    }

    return quizHeader
}

function createBackSide(question) {
    var quizConsoleWrapBack = document.createElement('div');
    quizConsoleWrapBack.className = 'quiz-console-wrap back';

    if (question != null) {
        quizConsoleWrapBack.id = 'back-' + question.questionId;
    }

    quizConsoleWrapBack.appendChild(createQuizHeader(question, true));

    var quizConsole = document.createElement('div');
    quizConsole.className = 'quiz-console';

    var quizBody = document.createElement('div');
    quizBody.className = 'quiz-body';

    quizConsole.appendChild(quizBody);

    var qQuestion = document.createElement('div');
    qQuestion.className = "q-question";
    quizConsole.appendChild(qQuestion);

    qQuestion.innerHTML = question.solution;

    quizConsoleWrapBack.appendChild(quizConsole);

    var quizFooter = document.createElement('div');
    quizFooter.className = "quiz-footer";

    var answerHinted = document.createElement('div');
    answerHinted.className = 'answer hinted';
    quizFooter.appendChild(answerHinted);

    var iconArrowLeft = document.createElement('i');
    iconArrowLeft.className = 'icon-arrow-left';
    answerHinted.appendChild(iconArrowLeft);

    var span = document.createElement('span');
    span.innerHTML = 'Return to Quiz';
    span.setAttribute('onclick', 'flipQuizWindow(' + question.questionId + ')');
    answerHinted.appendChild(span);

    quizConsoleWrapBack.appendChild(quizFooter);

    return quizConsoleWrapBack;

}

function createTopParentSwipeDiv(question) {
    var questionAndAnswersDiv = document.createElement('div');
    questionAndAnswersDiv.className = "quiz-console-parent";

    var quizTitle = document.createElement('div');
    quizTitle.className = 'quiz-title';
    quizTitle.innerHTML = quiz.name;

    questionAndAnswersDiv.appendChild(quizTitle);

    var quizConsoleWrap = document.createElement('div');
    quizConsoleWrap.className = 'quiz-console-wrap front';

    if (question != null) {
        quizConsoleWrap.id = 'front-' + question.questionId;
    }

    quizConsoleWrap.appendChild(createQuizHeader(question, false));

    questionAndAnswersDiv.appendChild(quizConsoleWrap);

    var quizConsole = document.createElement('div');

    if (question != null) {
        quizConsole.id = 'quiz-console-' + question.questionId;
    }

    quizConsole.className = 'quiz-console';
    quizConsoleWrap.appendChild(quizConsole);

    var quizBody = document.createElement('div');
    quizBody.className = 'quiz-body';
    if (question != null) {
        quizBody.id = 'quiz-body-' + question.questionId;
    }

    quizConsole.appendChild(quizBody);

    quizConsoleWrap.appendChild(createQuizFooter());

    if (question != null) {
        if (!isInformationType(question) && question.solution !== undefined && question.solution !== null
            && question.solution.length > 0) {

            questionAndAnswersDiv.appendChild(createBackSide(question));
        }

    }

    return questionAndAnswersDiv;
}

function createQuestion(divIn, question) {

    divIn.innerHTML = "";

    var questionType = new QuestionType(question.questionType);

    var questionResults = questionResultsArray[question.orderNum];

    function createAnswerDiv(answer, questionResults) {

        var iconI = document.createElement('i');
        iconI.id = 'answer-icon-' + answer.answerId;
        iconI.className = '';

        var answerDiv = document.createElement('div');
        answerDiv.setAttribute('class', 'answer');
        answerDiv.setAttribute('id', 'answer-' + answer.answerId);

        //console.log("questionResults=" + questionResults);

        if (questionResults !== undefined && questionResults !== null) {
            if (answer.answerId == questionResults.answerIds[0]) {

                if (questionResults.isGraded) {

                    if (questionResults.isCorrect) {
                        answerDiv.setAttribute('class', 'answer green');
                        iconI.className = 'icon-ok-circle';
                    } else {
                        answerDiv.setAttribute('class', 'answer red');
                        iconI.className = 'icon-remove-circle';
                    }

                } else {
                    iconI.className = 'icon-circle-blank';
                    //iconI.setAttribute('onclick', 'checkAnswer(' + questionResults.questionId + ',' + answer.answerId + ')');
                    setAnswerSelected(answerDiv, true);
                }

            }

        }

        //console.log("iconId=" + 'answer-icon-' + answer.answerId);

        answerDiv.appendChild(iconI);

        return answerDiv;
    }

    function createAnswersDiv(question) {
        var answersDiv = document.createElement('div');
        answersDiv.setAttribute('class', 'q-answers');
        answersDiv.setAttribute('id', 'answers-' + question.questionId);
        return answersDiv;
    }

    /*
     function setSelectedAnswerCallback(transaction, results) {

     if (results.rows.length > 0) {
     var row = results.rows.item(0);
     var id = row['answer_id'];

     var element = document.getElementById('answer-' + id);
     element.setAttribute('class', 'answer-selected');
     }
     }
     */

    function createFillInBlanksQuestion() {
        var questionString = question.text;

        var answerArray = question.answerBank.split(',');

        for (var i = 0; i < question.answers.length; i++) {
            var answer = new Answer(question.answers[i]);

            var key = '{' + answer.answerId + '}';

            var answerIndex = questionString.indexOf(key);

            if (answerIndex > -1) {

                var answerSelect = document.createElement('select');
                answerSelect.setAttribute('class', 'answer-fill-in');
                answerSelect.setAttribute('id', 'answer-fill-in-' + answer.answerId);
                answerSelect.setAttribute('onchange', 'selectFillInBlank(' + question.questionId + ',' + answer.answerId + ')');

                var option = document.createElement("option");

                option.setAttribute("value", "");
                option.innerText = "";
                answerSelect.appendChild(option);

                //console.log("answerArray.length=" + answerArray.length);

                for (var j = 0; j < answerArray.length; j++) {
                    option = document.createElement("option");
                    var answerValue = answerArray[j];
                    option.setAttribute("value", answerValue);
                    option.innerHTML = answerValue;
                    //option.appendChild(answerValue);
                    answerSelect.appendChild(option);
                }

                questionString = questionString.replace(key, answerSelect.outerHTML);

            }

        }

        return questionString;

    }

    function createQuestionTop() {
        var questionAndAnswersDiv = createTopParentSwipeDiv(question);

        var quizBody = questionAndAnswersDiv.getElementsByClassName('quiz-body')[0];

        var questionDiv = document.createElement('div');

        questionDiv.setAttribute('class', 'q-question');

        quizBody.appendChild(questionDiv);

        if (question.questionType.type == FILL_IN_TYPE) {
            questionDiv.innerHTML = createFillInBlanksQuestion();
        } else {
            questionDiv.innerHTML = question.text;
        }

        if (question.uri !== undefined && question.uri !== null) {

            var questionImageDiv = document.createElement('div');
            questionImageDiv.setAttribute('class', 'question-image-div');

            var questionImg = document.createElement('img');
            questionImg.setAttribute('class', 'question-image');
            questionImg.setAttribute('src', question.uri);
            questionImageDiv.appendChild(questionImg);

            quizBody.appendChild(questionImageDiv);
        }

        return questionAndAnswersDiv;
    }

    function createOrderAnswers() {
        //var i;

        /*
         function setAnswerDiv(answer) {
         var answerDiv = createAnswerDiv(answer);
         answerDiv.setAttribute('draggable', 'true');

         answerDiv.innerHTML = answer.text;
         answersDiv.appendChild(answerDiv);
         //makeDivDraggable(answerDiv);
         }
         */

        var questionAndAnswersDiv = createQuestionTop();
        questionAndAnswersDiv.setAttribute("id", "foo");

        //var answersDiv = createAnswersDiv(question);

    }

    function createMultipleSelect() {
        var questionAndAnswersDiv = createQuestionTop();

        var answersDiv = createAnswersDiv(question);

        for (var i = 0; i < question.answers.length; i++) {
            var answer = new Answer(question.answers[i]);
            var answerDiv = createAnswerDiv(answer);

            answerDiv.setAttribute('onclick', 'selectAnswerMultiple(' + question.questionId + ',' + answer.answerId + ')');

            answerDiv.setAttribute('ontouchstart', 'activeAnswer(' + "'" + answerDiv.id + "'" + ')');

            answerDiv.innerHTML = answer.text;
            answersDiv.appendChild(answerDiv);
        }

        questionAndAnswersDiv.appendChild(answersDiv);

        divIn.appendChild(questionAndAnswersDiv);

    }

    function createMultipleChoice() {
        var questionAndAnswersDiv = createQuestionTop();

        var answersDiv = createAnswersDiv(question);

        for (var i = 0; i < question.answers.length; i++) {

            var answer = new Answer(question.answers[i]);
            var answerDiv = createAnswerDiv(answer, questionResults);

            answerDiv.setAttribute('onclick', 'selectAnswer(' + question.questionId + ',' + answer.answerId + ', true )');

            answerDiv.setAttribute('ontouchstart', 'activeAnswer(' + "'" + answerDiv.id + "'" + ')');

            var answerSpan = document.createElement('span');
            answerSpan.id = 'answer-span' + answer.answerId;
            answerSpan.innerHTML = answer.text;

            answerDiv.appendChild(answerSpan);

            answersDiv.appendChild(answerDiv);
        }

        var scroll = questionAndAnswersDiv.getElementsByClassName("quiz-body");

        //console.log("scroll=" + scroll[0]);

        scroll[0].appendChild(answersDiv);

        // var console = questionAndAnswersDiv.getElementsByClassName("quiz-console-wrap front");

        //console[0].parentNode.appendChild(createQuizFooter());

        divIn.appendChild(questionAndAnswersDiv);
    }

    function createFillInBlanks() {
        var questionAndAnswersDiv = createQuestionTop();

        divIn.appendChild(questionAndAnswersDiv);
    }

    function createInformation() {
        var topDiv = createQuestionTop();

        divIn.appendChild(topDiv);
    }

    function createMultipleChoiceImages() {
        var questionAndAnswersDiv = createQuestionTop();

        var answersDiv = document.createElement('div');
        answersDiv.setAttribute('class', 'two-by-two');

        for (var i = 0; i < question.answers.length; i++) {
            var answer = new Answer(question.answers[i]);
            var boxDiv = document.createElement('div');
            boxDiv.setAttribute('class', 'box' + (i + 1));

            var answerDiv = document.createElement('div');
            answerDiv.setAttribute('class', 'answer');
            answerDiv.setAttribute('id', 'answer-' + answer.answerId);
            answerDiv.setAttribute('onclick', 'selectAnswer(' + question.questionId + ',' + answer.answerId + ', true)');
            answerDiv.setAttribute('ontouchstart', 'activeAnswer(' + "'" + answerDiv.id + "'" + ')');

            var img = document.createElement('img');
            img.setAttribute('class', "box-image");
            img.setAttribute('src', answer.uri);

            answersDiv.appendChild(boxDiv);
            boxDiv.appendChild(answerDiv);

            answerDiv.appendChild(img);

        }

        questionAndAnswersDiv.appendChild(answersDiv);
        divIn.appendChild(questionAndAnswersDiv);

    }

    switch (questionType.type) {
        case SELECT_TYPE :
            createMultipleChoice();
            break;
        case IMAGE_TYPE:
            createMultipleChoiceImages();
            break;
        case  MULTIPLE_TYPE :
            createMultipleSelect();
            break;

        case ORDER_TYPE:
            createOrderAnswers();
            break;

        case FILL_IN_TYPE:
            createFillInBlanks();
            break;

        case INFORMATION_TYPE:
            createInformation();
            break;

        default:
            divIn.innerHTML = questionType.type + " No processor found function createQuestion(listItem, question)";
            break;

    }
}

function generateQuestionsDiv(indexIn) {

    var question;
    var element;

    var i = 0;

//    console.log("quiz.lastPageIndex=" + quiz.lastPageIndex + "  quiz.questions.length=" + quiz.questions.length);

    if (indexIn == -1 || indexIn == 0) {
        for (i = 0; i < TOTAL_Q_DIVS - 1; i++) {
            question = new Question(quiz.questions[i]);
            element = document.getElementById('q' + i);
            createQuestion(element, question);
        }

        element = document.getElementById('q' + (TOTAL_Q_DIVS - 1));
        generateQuizResults(element);

    } else {

        var start = indexIn;

        for (i = 0; i < TOTAL_Q_DIVS - 1; i++) {

            if (start == quiz.questions.length) {
                element = document.getElementById('q' + (i));
                generateQuizResults(element);
                start = 0;
            } else {

                question = new Question(quiz.questions[start++]);
                element = document.getElementById('q' + i);
                createQuestion(element, question);
            }
        }

    }

    currentIndex = 0;
    currentDisplayedQuestionIndex = indexIn;

}

function hideQuiz() {
    document.getElementById("quiz-wrapper").style.display = 'none';

    computeAndSendQuizSeconds();

}

function slideCallBack(index) {

    var movingUp = isMovingUp(index);

    currentIndex = index;

    if (movingUp) {
        currentDisplayedQuestionIndex = (currentDisplayedQuestionIndex + 1) % (quiz.questions.length + 1);
    } else {
        currentDisplayedQuestionIndex = (currentDisplayedQuestionIndex - 1) % (quiz.questions.length + 1);

        if (currentDisplayedQuestionIndex < 0) {
            currentDisplayedQuestionIndex = quiz.questions.length;
        }
    }

    console.log("index=" + index + " movingUp=" + movingUp +
        " currentDisplayedQuestionIndex=" + currentDisplayedQuestionIndex + " ALLtotalQuestions=" + quiz.questions.length);

    if (currentDisplayedQuestionIndex == quiz.questions.length) {  // we at results
        checkAndSetAllAnswers();
    }

    redoDivsAfterSlide();

    sendLastIndexToWebSocket(currentDisplayedQuestionIndex);
}

function moveToTop() {

    //var element = document.getElementById('quiz-console');
    //element.scrollTop = 0;
    //element.scrollLeft = 0;
}

function redoDivsAfterSlide() {
    doLeftDiv();

    //console.log("currentIndex=" + currentIndex + " currentDisplayedQuestionIndex=" + currentDisplayedQuestionIndex);

    doRightDiv();

    moveToTop();

}

function isMovingUp(index) {
    var movingUp = true;

    if (currentIndex == 0) {
        if (index == TOTAL_Q_DIVS - 1) {
            movingUp = false;
        }
    } else if (currentIndex == TOTAL_Q_DIVS - 1) {
        if (index == TOTAL_Q_DIVS - 2) {
            movingUp = false;
        }
    } else if (index < currentIndex) {
        movingUp = false;
    }

    return movingUp;
}

function doLeftDiv() {
    var leftDiv = 0;

    if (currentIndex == 0) {
        leftDiv = TOTAL_Q_DIVS - 1;
    } else {
        leftDiv = currentIndex - 1;
    }

    var element = document.getElementById('q' + leftDiv);

    if (currentDisplayedQuestionIndex == 0) { // we're at results
        generateQuizResults(element);
    } else {

        var questionIndex = currentDisplayedQuestionIndex - 1;

        //console.log("leftDiv=" + leftDiv + " questionIndex=" + questionIndex);

        var question = new Question(quiz.questions[questionIndex]);
        createQuestion(element, question);
    }
}

function doRightDiv() {
    var rightDiv = 0;

    if (currentIndex != TOTAL_Q_DIVS - 1) {
        rightDiv = currentIndex + 1;
    }

    var element = document.getElementById('q' + rightDiv);

    if (currentDisplayedQuestionIndex == quiz.questions.length - 1) { // we're at results

        generateQuizResults(element);

    } else {

        var questionIndex = currentDisplayedQuestionIndex + 1;

        if (currentDisplayedQuestionIndex == quiz.questions.length) {
            questionIndex = 0;
        }

        //console.log("rightDiv=" + rightDiv + " questionIndex=" + questionIndex);

        var question = new Question(quiz.questions[questionIndex]);
        createQuestion(element, question);
    }
}

function checkAnswer(questionId, answerId, sendToWebSocket) {
    //console.log("checkAnswer --- questionId=" + questionId + "answerId=" + answerId);

    var question = quiz.findQuestion(questionId);
    //console.log("questionId=" + question.questionId);
    var answer = question.findAnswer(answerId);
    //console.log("answerId=" + answer.answerId);

    var isCorrect = check(question, answer);

    //console.log("iscorect=" + isCorrect);

    //setCorrectResultsOnResultsPage(question, isCorrect);

    var divId = 'answer-' + answer.answerId;
    var answerElement = document.getElementById(divId);

    //console.log("answerElement=" + answerElement);

    var iconId = 'answer-icon-' + answer.answerId;
    var iconElement = document.getElementById(iconId);

    if (iconElement !== null) {
        iconElement.removeAttribute("onclick");

        if (isCorrect) {
            answerElement.setAttribute('class', 'answer green');
            iconElement.className = 'icon-ok-circle';
        } else {
            iconElement.className = 'icon-remove-circle';
            answerElement.setAttribute('class', 'answer red');
        }
    }

    var answerResults = [];
    answerResults[0] = answerId;

    questionResultsArray[question.orderNum] =
        new QuestionResult(questionId, answerResults, isCorrect, true);

    if (sendToWebSocket) {
        var actionObject = new ActionData('SelectAnswer', quizId);
        actionObject.payload = questionResultsArray[question.orderNum];

        nativeAction(actionObject);
    }

}

function selectAnswer(questionId, answerId, sendToWebSocket) {

    var selectIconId = 'answer-icon-' + answerId;
    var selectIconElement = document.getElementById(selectIconId);

    if (selectIconElement !== null) {
        //console.log("selectIconElement.className=" + selectIconElement.className);

        if (selectIconElement.className.length > 0) { // already selected
            checkAnswer(questionId, answerId, sendToWebSocket);
            return;
        }
    }

    var question = quiz.findQuestion(questionId);

    for (var i = 0; i < question.answers.length; i++) {
        var a = new Answer(question.answers[i]);

        var divId = 'answer-' + a.answerId;
        var answerElement = document.getElementById(divId);

        var iconId = 'answer-icon-' + a.answerId;
        var iconElement = document.getElementById(iconId);

        if (answerElement !== null) {
            if (a.answerId == answerId) {
                setAnswerSelected(answerElement, true);
                iconElement.className = SELECTED_ICON;
                //iconElement.setAttribute('onclick', 'checkAnswer(' + questionId + ',' + answerId + ')');

            } else {
                setAnswerSelected(answerElement, false);
                iconElement.className = '';
                //iconElement.removeAttribute("onclick");

            }
        } else {
            // console.error("Cannot find div with id=" + divId);
        }
    }

    var answer = question.findAnswer(answerId);

    //answers[question.orderNum] = answerId;

    var answerResults = [];
    answerResults[0] = answerId;

    var isCorrect = check(question, answer);//, answers[question.orderNum]);
    //setAnswersNative(question.questionId, answerResults, isCorrect);

    questionResultsArray[question.orderNum] =
        new QuestionResult(questionId, answerResults, isCorrect, false);

    setCorrectResultsOnResultsPage(question, isCorrect);

    if (sendToWebSocket) {
        var actionObject = new ActionData('SelectAnswer', quizId);
        actionObject.payload = questionResultsArray[question.orderNum];

        nativeAction(actionObject);
    }

    //mobiSocket.sendObject(new QuestionClientData(questionId, answerResults, isCorrect, false));

}

function setAnswerSelected(element, selected) {

    if (element !== null) {
        if (selected) {
            element.setAttribute('class', 'answer selected');
        } else {
            element.setAttribute('class', 'answer');
        }
    } else {
        console.error("Element is null");
    }
}

function reVisitQuestion(questionOrder) {
    //generateQuestionsDiv();

    //console.log('questionOrder' + questionOrder);

    var q;

    for (var i = 0; i < quiz.questions.length; i++) {
        q = new Question(quiz.questions[i]);

        if (q.orderNum == questionOrder) {
            currentDisplayedQuestionIndex = i + 1;
            break
        }
    }

    if (q != null) {
        doLeftDiv();
        mySwipe.prev();
    }

}

/**
 *
 * @param results (Array of QuestionResult )
 */
function setQuestionResultsCallback(results) {

    for (var i = 0; i < results.length; i++) {
        var questionResult = results[i];

        var question = quiz.findQuestion(questionResult.questionId);
        questionResultsArray[question.orderNum] = questionResult;

        loadAnsweredResults(questionResult);
    }

}








