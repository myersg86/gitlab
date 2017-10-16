import Vue from 'vue';
import UserAvatarUsernameLink from '~/vue_shared/components/user_avatar/user_avatar_username_link.vue';

describe('User Avatar Username Link Component', () => {
  const propsData = {
    linkHref: `${gl.TEST_HOST}/`,
    imgSize: 99,
    imgSrc: `${gl.TEST_HOST}/image.png`,
    imgAlt: 'mydisplayname',
    imgCssClasses: 'myextraavatarclass',
    tooltipText: 'tooltip text',
    tooltipPlacement: 'bottom',
    text: 'text',
  };
  let vm;

  beforeEach(() => {
    const UserAvatarUsernameLinkComponent = Vue.extend(UserAvatarUsernameLink);
    vm = new UserAvatarUsernameLinkComponent({
      propsData,
    }).$mount();
  });

  it('should render <a> as a child element', () => {
    expect(vm.$el.tagName).toBe('A');
  });

  it('should link <a> to linkHref', () => {
    expect(vm.$el.href).toEqual(propsData.linkHref);
  });

  it('should have <img> as a child element', () => {
    expect(vm.$el.querySelector('img')).not.toBeNull();
  });

  it('should render <span> as a child element', () => {
    expect(vm.$el.querySelector('span')).not.toBeNull();
  });

  it('should render text prop in <span>', () => {
    expect(vm.$el.querySelector('span').innerText.trim()).toEqual(propsData.text);
  });

  it('should render text tooltip for <span>', () => {
    expect(vm.$el.querySelector('span').dataset.originalTitle).toEqual(propsData.tooltipText);
  });

  it('should render text tooltip placement for <span>', () => {
    expect(vm.$el.querySelector('span').getAttribute('tooltip-placement')).toEqual(propsData.tooltipPlacement);
  });
});
