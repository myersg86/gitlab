import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import PersistentUserCallout from '~/persistent_user_callout';
import Flash from '~/flash';

jest.mock('~/flash');

describe('PersistentUserCallout', () => {
  const dismissEndpoint = '/dismiss';
  const featureName = 'feature';

  function createStandardFixture() {
    const fixture = document.createElement('div');
    fixture.innerHTML = `
      <div
        class="container"
        data-dismiss-endpoint="${dismissEndpoint}"
        data-feature-id="${featureName}"
      >
        <button type="button" class="js-close"></button>
      </div>
    `;

    return fixture;
  }

  describe('invocation', () => {
    let mockAxios;

    beforeEach(() => {
      mockAxios = new MockAdapter(axios);
    });

    afterEach(() => {
      mockAxios.restore();
    });

    describe('dismiss', () => {
      let button;
      let persistentUserCallout;

      describe('without error data attribute', () => {
        beforeEach(() => {
          const fixture = createStandardFixture();
          const container = fixture.querySelector('.container');
          button = fixture.querySelector('.js-close');
          persistentUserCallout = new PersistentUserCallout(container);
          jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
        });

        it('POSTs endpoint and removes container when clicking close', () => {
          mockAxios.onPost(dismissEndpoint).replyOnce(200);

          button.click();

          return waitForPromises().then(() => {
            expect(persistentUserCallout.container.remove).toHaveBeenCalled();
            expect(mockAxios.history.post[0].data).toBe(
              JSON.stringify({ feature_name: featureName }),
            );
          });
        });

        it('invokes Flash when the dismiss request fails', () => {
          mockAxios.onPost(dismissEndpoint).replyOnce(500);

          button.click();

          return waitForPromises().then(() => {
            expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
            expect(Flash).toHaveBeenCalledWith(
              'An error occurred while dismissing the alert. Refresh the page and try again.',
            );
          });
        });
      });

      describe('with error data attribute', () => {
        let errorMessage;

        function createFixture(message) {
          const fixture = document.createElement('div');
          fixture.innerHTML = `
            <div
              class="container"
              data-dismiss-endpoint="${dismissEndpoint}"
              data-feature-id="${featureName}"
              data-error-message="${message}"
            >
              <button type="button" class="js-close"></button>
            </div>
          `;

          return fixture;
        }

        beforeEach(() => {
          errorMessage = 'custom error message';
          const fixture = createFixture(errorMessage);
          const container = fixture.querySelector('.container');
          button = fixture.querySelector('.js-close');
          persistentUserCallout = new PersistentUserCallout(container);
          jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
        });

        it('invokes Flash when the dismiss request fails', () => {
          mockAxios.onPost(dismissEndpoint).replyOnce(500);

          button.click();

          return waitForPromises().then(() => {
            expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
            expect(Flash).toHaveBeenCalledWith(errorMessage);
          });
        });
      });

      describe('with passed options instead of data attributes', () => {
        let errorMessage;

        function createFixture() {
          const fixture = document.createElement('div');
          fixture.innerHTML = `
            <div class="container">
              <button type="button" class="js-close"></button>
            </div>
          `;

          return fixture;
        }

        beforeEach(() => {
          errorMessage = 'custom error message';
          const fixture = createFixture();
          const container = fixture.querySelector('.container');
          button = fixture.querySelector('.js-close');
          persistentUserCallout = new PersistentUserCallout(container, {
            dismissEndpoint,
            featureId: featureName,
            errorMessage,
          });
          jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
        });

        it('POSTs endpoint and removes container when clicking close', () => {
          mockAxios.onPost(dismissEndpoint).replyOnce(200);

          button.click();

          return waitForPromises().then(() => {
            expect(persistentUserCallout.container.remove).toHaveBeenCalled();
            expect(mockAxios.history.post[0].data).toBe(
              JSON.stringify({ feature_name: featureName }),
            );
          });
        });

        it('invokes Flash when the dismiss request fails', () => {
          mockAxios.onPost(dismissEndpoint).replyOnce(500);

          button.click();

          return waitForPromises().then(() => {
            expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
            expect(Flash).toHaveBeenCalledWith(errorMessage);
          });
        });
      });
    });

    describe('deferred links', () => {
      let button;
      let deferredLink;
      let normalLink;
      let persistentUserCallout;
      let windowSpy;

      function createDeferredLinkFixture() {
        const fixture = document.createElement('div');
        fixture.innerHTML = `
          <div
            class="container"
            data-dismiss-endpoint="${dismissEndpoint}"
            data-feature-id="${featureName}"
            data-defer-links="true"
          >
            <button type="button" class="js-close"></button>
            <a href="/somewhere-pleasant" target="_blank" class="deferred-link">A link</a>
            <a href="/somewhere-else" target="_blank" class="normal-link">Another link</a>
          </div>
        `;

        return fixture;
      }

      beforeEach(() => {
        const fixture = createDeferredLinkFixture();
        const container = fixture.querySelector('.container');
        button = fixture.querySelector('.js-close');
        deferredLink = fixture.querySelector('.deferred-link');
        normalLink = fixture.querySelector('.normal-link');
        persistentUserCallout = new PersistentUserCallout(container);
        jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
        windowSpy = jest.spyOn(window, 'open').mockImplementation(() => {});
      });

      it('defers loading of a link until callout is dismissed', () => {
        const { href, target } = deferredLink;
        mockAxios.onPost(dismissEndpoint).replyOnce(200);

        deferredLink.click();

        return waitForPromises().then(() => {
          expect(windowSpy).toHaveBeenCalledWith(href, target);
          expect(persistentUserCallout.container.remove).toHaveBeenCalled();
          expect(mockAxios.history.post[0].data).toBe(
            JSON.stringify({ feature_name: featureName }),
          );
        });
      });

      it('does not dismiss callout on non-deferred links', () => {
        normalLink.click();

        return waitForPromises().then(() => {
          expect(windowSpy).not.toHaveBeenCalled();
          expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
        });
      });

      it('does not follow link when notification is closed', () => {
        mockAxios.onPost(dismissEndpoint).replyOnce(200);

        button.click();

        return waitForPromises().then(() => {
          expect(windowSpy).not.toHaveBeenCalled();
          expect(persistentUserCallout.container.remove).toHaveBeenCalled();
        });
      });
    });

    describe('follow links', () => {
      let link;
      let persistentUserCallout;

      describe('without error data attribute', () => {
        function createFollowLinkFixture() {
          const fixture = document.createElement('div');
          fixture.innerHTML = `
            <ul>
              <li
                class="container"
                data-dismiss-endpoint="${dismissEndpoint}"
                data-feature-id="${featureName}"
              >
                <a class="js-follow-link" href="/somewhere-pleasant">A Link</a>
              </li>
            </ul>
        `;

          return fixture;
        }

        beforeEach(() => {
          const fixture = createFollowLinkFixture();
          const container = fixture.querySelector('.container');
          link = fixture.querySelector('.js-follow-link');
          persistentUserCallout = new PersistentUserCallout(container);
          jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});

          delete window.location;
          window.location = { assign: jest.fn() };
        });

        it('uses a link to trigger callout and defers following until callout is finished', () => {
          const { href } = link;
          mockAxios.onPost(dismissEndpoint).replyOnce(200);

          link.click();

          return waitForPromises().then(() => {
            expect(window.location.assign).toBeCalledWith(href);
            expect(mockAxios.history.post[0].data).toBe(
              JSON.stringify({ feature_name: featureName }),
            );
            expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
          });
        });

        it('invokes Flash when the dismiss request fails', () => {
          mockAxios.onPost(dismissEndpoint).replyOnce(500);

          link.click();

          return waitForPromises().then(() => {
            expect(window.location.assign).not.toHaveBeenCalled();
            expect(Flash).toHaveBeenCalledWith(
              'An error occurred while acknowledging the notification. Refresh the page and try again.',
            );
          });
        });
      });

      describe('with error data attribute', () => {
        let errorMessage;

        function createFollowLinkFixture(message) {
          const fixture = document.createElement('div');
          fixture.innerHTML = `
            <ul>
              <li
                class="container"
                data-dismiss-endpoint="${dismissEndpoint}"
                data-feature-id="${featureName}"
                data-error-message="${message}"
              >
                <a class="js-follow-link" href="/somewhere-pleasant">A Link</a>
              </li>
            </ul>
        `;

          return fixture;
        }

        beforeEach(() => {
          errorMessage = 'custom error message';
          const fixture = createFollowLinkFixture(errorMessage);
          const container = fixture.querySelector('.container');
          link = fixture.querySelector('.js-follow-link');
          persistentUserCallout = new PersistentUserCallout(container);
          jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});

          delete window.location;
          window.location = { assign: jest.fn() };
        });

        it('invokes custom Flash message when the dismiss request fails', () => {
          mockAxios.onPost(dismissEndpoint).replyOnce(500);

          link.click();

          return waitForPromises().then(() => {
            expect(window.location.assign).not.toHaveBeenCalled();
            expect(Flash).toHaveBeenCalledWith(errorMessage);
          });
        });
      });
    });
  });

  describe('factory', () => {
    it('returns an instance of PersistentUserCallout with the provided container property', () => {
      const fixture = createStandardFixture();

      expect(PersistentUserCallout.factory(fixture) instanceof PersistentUserCallout).toBe(true);
    });

    it('returns undefined if container is falsey', () => {
      expect(PersistentUserCallout.factory()).toBe(undefined);
    });
  });
});
