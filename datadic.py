import requests
import pandas as pd
import json


BASE_URL = "https://test-api.wens.com.cn/dda/v1"


class WensDictionary:


    def __init__(self):

        self.session = requests.Session()

        self.headers = {
            "User-Agent": "Mozilla/5.0",
            "Content-Type": "application/json"
        }


    def get_entity_id(self, table_key):
        """
        根据表key获取实体ID
        """

        url = f"{BASE_URL}/cqentities"

        params = {
            "key": table_key
        }


        response = self.session.get(
            url,
            params=params,
            headers=self.headers
        )


        response.raise_for_status()


        result = response.json()


        print("\n========== cqentities返回 ==========")

        print(
            json.dumps(
                result,
                ensure_ascii=False,
                indent=2
            )
        )


        if result.get("code") != 1:
            raise Exception(
                f"查询实体失败: {result}"
            )


        data = result.get("data")


        if not data:
            raise Exception(
                "没有找到对应表"
            )


        # 兼容 list / dict

        if isinstance(data, list):

            entity = data[0]

        else:

            entity = data


        entity_id = entity.get("id")


        if not entity_id:
            raise Exception(
                "返回结果中没有id"
            )


        print("\n实体信息:")
        print("表名:", table_key)
        print("ID:", entity_id)


        return entity_id



    def get_detail(self, entity_id):
        """
        根据实体ID获取数据字典详情
        """


        url = f"{BASE_URL}/cqdetail"


        payload = {
            "id": entity_id
        }


        response = self.session.post(
            url,
            json=payload,
            headers=self.headers
        )


        response.raise_for_status()


        result = response.json()


        print("\n========== cqdetail返回 ==========")


        print(
            json.dumps(
                result,
                ensure_ascii=False,
                indent=2
            )[:2000]
        )


        return result



    def parse_fields(self, detail):

        """
        解析字段信息
        """


        field_list = (
            detail
            .get("data", {})
            .get("fieldList", [])
        )


        if not field_list:

            raise Exception(
                "没有找到字段信息"
            )


        rows = []


        for field in field_list:


            relation = field.get(
                "relation"
            )


            rows.append({

                "字段中文名":
                    field.get("name"),


                "字段key":
                    field.get("key"),


                "数据库字段":
                    field.get("fieldName"),


                "字段类型":
                    field.get("nodeName"),


                "是否必填":
                    field.get("mustInput"),


                "允许为空":
                    field.get("enableNull"),


                "关联表":
                    relation.get("number")
                    if relation
                    else None,


                "字段ID":
                    field.get("id")

            })


        return rows



    def export_excel(
            self,
            rows,
            table_key
    ):


        df = pd.DataFrame(rows)


        filename = (
            f"{table_key}_数据字典.xlsx"
        )


        df.to_excel(
            filename,
            index=False
        )


        print("\n==============================")
        print("数据字典生成成功:")
        print(filename)
        print("==============================")



def main():


    table_key = input(
        "请输入表名(key): "
    ).strip()


    client = WensDictionary()


    # 第一步：获取ID

    entity_id = client.get_entity_id(
        table_key
    )


    # 第二步：获取字段详情

    detail = client.get_detail(
        entity_id
    )


    # 保存原始JSON

    with open(
        f"{table_key}.json",
        "w",
        encoding="utf-8"
    ) as f:


        json.dump(
            detail,
            f,
            ensure_ascii=False,
            indent=4
        )


    # 第三步：解析字段

    fields = client.parse_fields(
        detail
    )


    print(
        f"\n字段数量: {len(fields)}"
    )


    # 第四步：生成Excel

    client.export_excel(
        fields,
        table_key
    )



if __name__ == "__main__":

    main()