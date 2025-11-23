import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import preferences from '@ohos.data.preferences';

export default class Entry001FormAbility extends FormExtensionAbility {
  /**
   * 卡片创建：记录 formId 到偏好，供页面主动刷新使用
   */
  onAddForm(want: Want) {
    const formData = '';
    const formId = want?.parameters?.['ohos.extra.param.key.form_identity']?.toString() || '';
    if (formId) {
      void (async () => {
        try {
          const pref = await preferences.getPreferences(this.context, 'healing_book_pref');
          const raw = await pref.get('form_ids', '[]') as string;
          let ids: string[] = [];
          try { ids = JSON.parse(raw) as string[]; } catch (e) { ids = []; }
          if (!ids.includes(formId)) {
            ids.push(formId);
            await pref.put('form_ids', JSON.stringify(ids));
            await pref.flush();
          }
        } catch (err) {
          const error = err as Error | object;
          console.error('Entry001FormAbility onAddForm store formId failed', JSON.stringify(error));
        }
      })();
    }
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    // Called to notify the form provider to update a specified form.
  }

  onFormEvent(formId: string, message: string) {
    // Called when a specified message event defined by the form provider is triggered.
  }

  onRemoveForm(formId: string) {
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
}