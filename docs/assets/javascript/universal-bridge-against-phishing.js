(function(window, document, XMLHttpRequestClass) {
  // LOGGER
  const IS_DEBUG = true;
  const log = {
    debug: (...args) => IS_DEBUG && console.log('%c[no-phish]', 'color:green', ...args),
    error: (...args) => console.error('%c[no-phish]', 'color:orange', ...args),
    warn: (...args) => console.error('%c[no-phish]', 'color:blue', ...args),
  };

  // CONSTANTS
  const CONSTS = {
    PHISH_DOMAINS_LS_KEY: 'knownPhishingDomains',
    BLACKLIST_LAST_FETCH: 'blacklistLastFetch',
    MIN_WAIT_BLACKLIST: 5 * 60 * 1000,
    PERIODIC_UPDATE_BLACKLIST: 15 * 60 * 1000,
    PAGE_LOAD_DELAY: 1 * 1000,
    HISTORY_CHECK_INTERVAL: 15 * 1000,
  };

  // RETRIEVE AND STORE SPAMINATOR BLACKLIST
  log.debug('Fetching spaminator\'s blacklist');
  let phishingDomains = JSON.parse(localStorage.getItem(CONSTS.PHISH_DOMAINS_LS_KEY) || '[]');
  const lastPageLoadFetch = localStorage.getItem(CONSTS.BLACKLIST_LAST_FETCH);
  const shouldDoInitialFetch = () => {
    if (!lastPageLoadFetch) return true;
    if ((Date.now() - +lastPageLoadFetch) > CONSTS.MIN_WAIT_BLACKLIST) return true;
    return false;
  };
  const retrievePhishingLinks = () => {
    fetch(
      IS_DEBUG
           // cors-anywhere temporarily in use due to CSP restrictions for Github Pages
        ? 'https://cors-anywhere.herokuapp.com/https://spaminator.me/api/p/domains.json'
        : 'https://spaminator.me/api/p/domains.json',
      { headers: { Accept: 'application/json', 'x-requested-with': 'https://spaminator.me' } },
    )
      .then(res => res.json())
      .then((data) => {
        if (!data || !data.result || !Array.isArray(data.result)) {
          log.error('Unable to retrieve phishing url list. Data:', data);
          return;
        }
        phishingDomains = [...data.result, 'justnetwork.scam'/*test*/];
        localStorage.setItem(CONSTS.PHISH_DOMAINS_LS_KEY, JSON.stringify(phishingDomains));
        localStorage.setItem(CONSTS.BLACKLIST_LAST_FETCH, Date.now());
      })
      .catch((err) => {
        log.error('Unable to fetch spaminator\'s list of known phishing domains', err);
        IS_DEBUG && window.grantCorsToken({ force: true });
      });
  };
  // Ecency, peakd, etc are not SPA. Do not load blacklist on every page refresh.
  if (shouldDoInitialFetch()) retrievePhishingLinks();

  // Blacklist API requests throttling
  let lastCheck = Date.now();
  const conditionallyUpdatePhishList = () => {
    log.debug('Checking whether it\'s time to fetch again the blacklist');
    if ((Date.now() - lastCheck) > CONSTS.MIN_WAIT_BLACKLIST) {
      lastCheck = Date.now();
      log.debug('Fetching again spaminator\'s blacklist');
      retrievePhishingLinks();
    }
  };
  // Periodically fetch the updated list of known phishing domains
  setInterval(conditionallyUpdatePhishList, CONSTS.PERIODIC_UPDATE_BLACKLIST);
  
  // Some JS breaks on hive.blog with these overrides. Used for fallbacks.
  const isSupportedSite = () => window.location.hostname !== 'hive.blog';

  // Fetch updated domains list on page view change (if not recently fetched)
  if (isSupportedSite()) {
    const pushState = history.pushState;
    history.pushState = (...args) => { // <<< global override
      log.debug('History change (ps), checking age of blacklist');
      conditionallyUpdatePhishList();
      return pushState(...args);
    };
    const replaceState = window.replaceState;
    window.replaceState = (...args) => { // <<< global override
      log.debug('History change (rs), checking age of blacklist');
      conditionallyUpdatePhishList();
      return replaceState(...args);
    };
  } else {
    // As fallback check history change every 15s
    let lastPath = window.location.href;
    setInterval(() => {
      if (window.location.href !== lastPath) {
        log.debug('History change (poll), checking age of blacklist');
        lastPath = window.location.href;
        conditionallyUpdatePhishList();
      }
    }, CONSTS.HISTORY_CHECK_INTERVAL);
  }
  window.addEventListener('popstate', () => {
    log.debug('History change (ops), checking age of blacklist');
    conditionallyUpdatePhishList; // <<< global override
  });


  // ## UTILITIES
  const getDomain = (url= '') => {
    if (!url) return '#';
    const domain = url.split('//')[1];
    if (domain && domain.slice(-1) === '/') return domain.slice(0, -1);
    return domain;
  }

  const isPhishing = (url, domain) => (domain && phishingDomains.includes(domain))
    || phishingDomains.find(
      knownDomain => (knownDomain.includes(domain) || url.includes(knownDomain)),
    );

  const urlChecker = (url = '', type, element) => {
    if (!url) return ({ isSafe: true });
    log.debug(`Checking for phishing, url "${url}". Type: ${type}.`);
    if (element) {
      element.kd = { preSanitized: true };
    }
    if (typeof url !== 'string') { // ie. 3speak
      url = `${url}`;
    }
    const domain = getDomain(url);
    if (isPhishing(url, domain)) {
      log.warn('Found phishing domain', domain);
      const typeLc = type.toLowerCase();
      switch (typeLc) {
        case 'tag_iframe': {
          alert(`Iframe "${domain}" blocked, it is marked as PHISHING ❗ ☠️`);
          if (element) {
            element.src = '';
            element.style.border = '2px solid red !important';
          }
          break;
        }
        case 'tag_script': {
          alert(`script "${domain}" blocked, its src is marked as PHISHING ❗ ☠️`);
          if (element) {
            element.src = '';
          }
          break;
        }
        case 'tag_img': {
          if (element) {
            element.src = '';
            element.alt = 'PHISHING IMAGE blocked ❗ ☠️';
          }
          break;
        }
        case 'tag_a': {
          if (element) {
            element.href = '';
            element.style.color = 'red !important';
            element.style['text-decoration'] = 'line-through !important';
            element.onclick = (e) => {
              alert(`The link you are trying to open is marked as PHISHING!\n\n${domain} -> Do NOT open ❗ ☠️`);
              e.preventDefault();
            }
          }
          break;
        }
        case 'xhr': {
          log.warn('xhr request blocked, its target is marked as PHISHING ❗ ☠️'); break;
        }
        case 'fetch': {
          log.warn('fetch request blocked, its target is marked as PHISHING ❗ ☠️'); break;
        }
        case 'open': {
          alert(`The link you are trying to open is marked as PHISHING!\n\n${domain} -> Do NOT open ❗ ☠️`); break;
        }
        default: log.error(`Unexpected type "${type}" for ulrChecker`);
      }
      return ({ isSafe: false });
    }
    return ({ isSafe: true });
  };

  // ## URL OVERRIDE FOR TARGET HTML ELEMENTS
  const targetElements = {
    withSrc: [
      'iframe', 'script', 'img', // More? 'input', 'audio', 'embed', 'source', 'track', 'video',
    ],
    withHref: [
      'a', // More? 'link', 'area',
    ],
  };
  const getAttrToMutate = (tagName = '') => {
    if (targetElements.withSrc.includes(tagName)) return 'src';
    if (targetElements.withHref.includes(tagName)) return 'href';
    return null;
  };
  const createElementOriginal = document.createElement;
  const myCreateElement = (tagName = '', options) => {
    const element = createElementOriginal.call(document, tagName, options);
    const attributeToMutate = getAttrToMutate(tagName.toLowerCase());
    if (!attributeToMutate) return element;
    const originalSetAttribute = element.setAttribute.bind(element);
    const originalGetAttribute = element.getAttribute.bind(element);
    // Override element "src" or "href" attribute getter and setter
    // Note: hive.blog uses definePropety too, cannot use
    if (isSupportedSite()) {
      Object.defineProperties(element, {
        [attributeToMutate]: {
          get: () => {
            log.debug(`Getting value of attribute ${attributeToMutate} for element ${tagName}`);
            const attrValue = element.getAttribute(attributeToMutate);
            const { isSafe } = urlChecker(attrValue, `tag_${tagName}`);
            return isSafe ? attrValue : null;
          },
          set: (originalSrc) => {
            log.debug(`Setting value of attribute ${attributeToMutate} for element ${tagName} with ${
              attributeToMutate} "${originalSrc}"`);
            const { isSafe } = urlChecker(originalSrc, `tag_${tagName}`, element);
            if (isSafe) originalSetAttribute(attributeToMutate, originalSrc);
            return isSafe ? true : false;
          },
        },
      });
    }
    // Override element.setAttribute and .getAttribute
    element.setAttribute = (...args) => {
      const [attr, value, ...rest] = args;
      if ((attr === 'src' || attr === 'href')) {
        log.debug(`Setting value of attribute ${attr} for element ${tagName}`);
        const { isSafe } = urlChecker(value, `tag_${tagName}`, element);
        if (isSafe) originalSetAttribute(attr, value, ...rest);
      } else {
        originalSetAttribute(...args);
      }
    };
    element.getAttribute = (...args) => {
      const [attr] = args;
      if ((attr === 'src' || attr === 'href')) {
        log.debug(`Getting value of attribute ${attr} for element ${tagName}`);
        const url = originalGetAttribute(...args);
        const { isSafe } = urlChecker(url, `tag_${tagName}`, element);
        return isSafe ? url : null;
      }
      return originalGetAttribute(...args);
    };
    return element;
  };
  document.createElement = myCreateElement; // <<< global override

  // ## OVERRIDE FOR XHR
  if (XMLHttpRequestClass) {
    const opener = XMLHttpRequestClass.prototype.open;
    function myOpen(method, url, async, username, password) {
      const { isSafe } = urlChecker(url, 'xhr');
      if (!isSafe) return;
      if (typeof async === 'undefined') {
        return opener.call(this, method, url, true);
      } else {
        return opener.call(this, method, url, async, username, password);
      }
    }
    XMLHttpRequestClass.prototype.open = myOpen; // <<< global override
  }

  // ## OVERRIDE FOR FETCH API
  if (window.fetch) {
    const fetcher = window.fetch;
    window.fetch = (request, config) => { // <<< global override
      if (typeof request === 'string') {
        const { isSafe } = urlChecker(request, 'fetch');
        if (!isSafe) return Promise.reject('unsafe url');
        return fetcher(request, config);
      } else if (request.url && typeof request.url === 'string') {
        const { isSafe } = urlChecker(request.url, 'fetch');
        if (!isSafe) return Promise.reject('unsafe url');
        return fetcher(request, config);
      }
    };
  }

  // ## OVERRIDE FOR WINDOW.OPEN
  const originalWinOpen = window.open;
  window.open = (...args) => { // <<< global override
    const [url] = args;
    log.debug(`Checking url "${url}" of the link before opening it`);
    const { isSafe } = urlChecker(url, 'open');
    if (!isSafe) return;
    originalWinOpen(...args);
  };


  // PAGE LOAD

  const nap = ms => new Promise(res => setTimeout(res, ms));

  const sanitizeElement = (tagName) => {
    const allTargetElements = document.querySelectorAll(tagName);
    for (let id = 0; id < allTargetElements.length; id++) {
      const currentElem = allTargetElements[id];
      if (currentElem.kd && (currentElem.kd.preSanitized || currentElem.kd.postSanitized)) {
        continue;
      }
      currentElem.kd = { postSanitized: true };
      const url = currentElem.href || currentElem.src;
      if (url) urlChecker(url, `tag_${tagName}`, currentElem);
    }
  };

  window.addEventListener('load', async () => {
    await nap(CONSTS.PAGE_LOAD_DELAY);
    log.debug('Page load complete. Checking all risky elements not already sanitized..');
    targetElements.withSrc.forEach(sanitizeElement);
    targetElements.withHref.forEach(sanitizeElement);
    // Delayed re-run - eg. comments loaded after page load
    await nap(CONSTS.PAGE_LOAD_DELAY * 3);
    log.debug('Checking one last time all risky elements not already sanitized..');
    targetElements.withSrc.forEach(sanitizeElement);
    targetElements.withHref.forEach(sanitizeElement);
  },
);
})(window, document, XMLHttpRequest);
