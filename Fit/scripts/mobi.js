
var pageScrollMax = 0.0;


window.onscroll = function (oEvent) {
    //only record the max value when scrolling
    pageScrollMax = Math.max(pageScrollMax, computeScrollPercentage());
}


window.onload = function () {
    //if page has no scrolling allowed will report to 100% so set pageScrollMax to this
    pageScrollMax = computeScrollPercentage();

    // send ID to native layer needs to save and start timer for length of time on page - PAGE_ID IS defined on html page
    Android.load(PAGE_ID);

    // SCROLL_PERCENTAGE needs to be defined when page is generated
    console.log("SCROLL_PERCENTAGE=" + SCROLL_PERCENTAGE);

    if (SCROLL_PERCENTAGE > 0) {
        var topper = computeScrollPosition(SCROLL_PERCENTAGE);
        setPosition(topper);
    }
}

function setPosition(topper) {
    if (topper > 0) {
        window.scrollTo(0, topper);
    }
}


function getPercentageAndPosition() {

    var domElement = document.documentElement;

    var body = document.body;
    var html = document.documentElement;

    var position = body.scrollTop;
    var percentage = computeScrollPercentage();
    console.log("percentage=" + percentage);
    console.log("pageScrollMax=" + pageScrollMax);

    Android.sendBackPosition(percentage, pageScrollMax);
}

function setElementScrollScale(scale) {
    var domElement = document.documentElement;

    domElement.scrollTop = (domElement.scrollHeight - domElement.clientHeight) * scale;
}


/**
 * Get current browser viewpane heigtht
 */
function getWindowHeight() {
    return window.innerHeight ||
        document.documentElement.clientHeight ||
        document.body.clientHeight || 0;
}

/**
 * Get current absolute window scroll position
 */
function getWindowYScroll() {
    return window.pageYOffset ||
        document.body.scrollTop ||
        document.documentElement.scrollTop || 0;
}

/**
 * Get current absolute document height
 */
function getDocHeight() {
    return Math.max(
        document.body.scrollHeight || 0,
        document.documentElement.scrollHeight || 0,
        document.body.offsetHeight || 0,
        document.documentElement.offsetHeight || 0,
        document.body.clientHeight || 0,
        document.documentElement.clientHeight || 0
    );
}


/**
 * Get current vertical scroll percentage
 */
function computeScrollPercentage() {
    return ((getWindowYScroll() + getWindowHeight()) / getDocHeight()) * 100;
}


function computeScrollPosition(percentage) {
    percentage = percentage / 100;
    return (percentage * getDocHeight()) - getWindowHeight();
}









