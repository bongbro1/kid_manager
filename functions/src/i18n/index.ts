import en from "./en.json";
import vi from "./vi.json";

type Dict = Record<string, string>;

const dictionaries: Record<string, Dict> = {
en,
vi,
};

export function t(
  locale: string | undefined,
  key: string,
  params?: Record<string, string>
): string {
  const lang = (locale || "vi").toLowerCase().startsWith("en") ? "en" : "vi";
  let value = dictionaries[lang][key] || key;

  if (params) {
    for (const [k, v] of Object.entries(params)) {
value = value.split(`{${k}}`).join(v);    }
  }

  return value;
}