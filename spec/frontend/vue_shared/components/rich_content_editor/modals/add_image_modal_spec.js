import { shallowMount } from '@vue/test-utils';
import { GlModal, GlTabs } from '@gitlab/ui';
import AddImageModal from '~/vue_shared/components/rich_content_editor/modals/add_image_modal.vue';
import { IMAGE_TABS } from '~/vue_shared/components/rich_content_editor/constants';

describe('Add Image Modal', () => {
  let wrapper;

  const findModal = () => wrapper.find(GlModal);
  const findTabs = () => wrapper.find(GlTabs);
  const findFileInput = () => wrapper.find({ ref: 'fileInput' });
  const findUrlInput = () => wrapper.find({ ref: 'urlInput' });
  const findDescriptionInput = () => wrapper.find({ ref: 'descriptionInput' });

  beforeEach(() => {
    wrapper = shallowMount(AddImageModal, { provide: { glFeatures: { sseImageUploads: true } } });
  });

  describe('when content is loaded', () => {
    it('renders a modal component', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('renders a Tabs component', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders a file input to add an image', () => {
      expect(findFileInput().exists()).toBe(true);
    });

    it('renders an input to add an image URL', () => {
      expect(findUrlInput().exists()).toBe(true);
    });

    it('renders an input to add an image description', () => {
      expect(findDescriptionInput().exists()).toBe(true);
    });
  });

  describe('add image', () => {
    describe('Upload', () => {
      it.each`
        size          | isValid
        ${2000000000} | ${false}
        ${200}        | ${true}
      `('validates the file correctly', ({ size, isValid }) => {
        const preventDefault = jest.fn();
        const description = 'some description';
        const file = { size };
        const payload = isValid ? [[{ file, altText: description }]] : undefined;

        wrapper.vm.$refs.fileInput = { files: [file] };
        wrapper.setData({ description, tabIndex: IMAGE_TABS.UPLOAD_TAB });

        findModal().vm.$emit('ok', { preventDefault });
        expect(wrapper.emitted('uploadImage')).toEqual(payload);
      });
    });

    describe('URL', () => {
      it('emits an addImage event when a valid URL is specified', () => {
        const preventDefault = jest.fn();
        const mockImage = { imageUrl: '/some/valid/url.png', description: 'some description' };
        wrapper.setData({ ...mockImage, tabIndex: IMAGE_TABS.URL_TAB });

        findModal().vm.$emit('ok', { preventDefault });
        expect(preventDefault).not.toHaveBeenCalled();
        expect(wrapper.emitted('addImage')).toEqual([
          [{ imageUrl: mockImage.imageUrl, altText: mockImage.description }],
        ]);
      });
    });
  });
});
