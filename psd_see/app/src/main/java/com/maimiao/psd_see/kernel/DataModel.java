package com.maimiao.psd_see.kernel;

import com.j256.ormlite.dao.Dao;
import com.j256.ormlite.field.DatabaseField;
import com.j256.ormlite.stmt.QueryBuilder;
import com.j256.ormlite.table.DatabaseTable;
import com.maimiao.psd_see.common.LogTrace;

import java.io.File;
import java.sql.SQLException;
import java.util.List;

/**
 * Created by larry on 17/1/8.
 */

public class DataModel {

    static public class ListItem
    {
        private int mType;
        private int mSubType;

        public ListItem(int type, int subType)
        {
            mType = type;
            mSubType = subType;
        }

        public int getViewType()
        {
            // TODO Auto-generated method stub
            return mType;
        }

        public int getViewSubType()
        {
            // TODO Auto-generated method stub
            return mSubType;
        }
    }

    /**
     * sdcard文件信息
     */
    @DatabaseTable(tableName = "sdcard_file_info_ex")
    public static class SDCardFileItemEx{
        public static final int PAGE_SIZE = 60;

        public static final String F_ITEM_INDEX = "item_index";
        public static final String F_FILE_TYPE = "file_type";

        @DatabaseField(columnName = FileItemEx.F_FILE_PATH, id = true)
        public String filePath; //文件路径

        @DatabaseField(columnName = F_ITEM_INDEX)
        public int itemIndex; //索引信息

        @DatabaseField(columnName = F_FILE_TYPE)
        public String fileType; //文件类型

        @DatabaseField(columnName = FileItemEx.F_FILE_SIZE)
        public long fileSize; //文件的大小

        @DatabaseField(columnName = FileItemEx.F_WIDTH)
        public int width; //文件的宽度

        @DatabaseField(columnName = FileItemEx.F_HEIGHT)
        public int height; //文件的高度

        public void save(){
            try{
                Dao<SDCardFileItemEx, String> dao = KernelManager._GetObject()
                        .getDatabaseHelper().getDao(SDCardFileItemEx.class);
                dao.createOrUpdate(this);
            }
            catch (Exception e){
                e.printStackTrace();
            }
        }

        /**
         * 对sd卡文件进行分页处理
         * @param pageIndex 从0开始
         * @return
         */
        public static List<?> getFileList(int pageIndex){
            List<SDCardFileItemEx> list = null;
            File file = null;
            int index = 0;
            SDCardFileItemEx item = null;

            try
            {
                Dao<SDCardFileItemEx, String> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(SDCardFileItemEx.class);

                //list = dao.queryForAll();
                QueryBuilder<SDCardFileItemEx, String> queryBuilder = dao.queryBuilder();
                queryBuilder.where()
                        .ge(F_ITEM_INDEX, pageIndex * PAGE_SIZE + 1);
                list = queryBuilder.limit(PAGE_SIZE).query();

                while (index < list.size()) {
                    item = list.get(index);
                    file = new File(item.filePath);
                    if (false == file.exists()) {
                        file.delete();
                        list.remove(index);
                        dao.delete(item);
                        LogTrace.log("image not exist:" + item.filePath);
                    } else {
                        index++;
                    }
                }


                LogTrace.log("list.size:" + list.size());
            }
            catch (SQLException e)
            {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }

            return list;
        }

        public static long getFileCount()
        {
            long itemCount = 0;
            try
            {
                Dao<SDCardFileItemEx, String> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(SDCardFileItemEx.class);
                itemCount = dao.countOf();
            }
            catch (SQLException e)
            {
                e.printStackTrace();
            }

            return itemCount;
        }

        public static void delete(SDCardFileItemEx file){
            try {
                Dao<SDCardFileItemEx, String> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(SDCardFileItemEx.class);
                dao.delete(file);
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        /**
         * 清除所有数据
         */
        public static void removeAll() {
            try {
                Dao<SDCardFileItemEx, String> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(SDCardFileItemEx.class);
                dao.deleteBuilder().delete();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }

    @DatabaseTable(tableName = "server_info")
    public static class ServerInfo {
        public static final String F_SVR_ID = "server_id";
        public static final String F_SERVER_IP = "server_ip";
        public static final String F_PASSWORD = "password";
        public static final String F_LAST_TIME = "last_time";

        @DatabaseField(columnName = F_SVR_ID, generatedId = true)
        public int itemId;

        @DatabaseField(columnName = F_SERVER_IP)
        public String serverIp;

        @DatabaseField(columnName = F_PASSWORD)
        public String password;

        @DatabaseField(columnName = F_LAST_TIME)
        public long visitTime;

        public boolean selected; //是否被选中

        public void save(){
            try{
                Dao<ServerInfo, Integer> dao = KernelManager._GetObject()
                        .getDatabaseHelper().getDao(ServerInfo.class);
                visitTime = System.currentTimeMillis();
                dao.createOrUpdate(this);
            }
            catch (Exception e){
                e.printStackTrace();
            }
        }

        public static ServerInfo getServer(String serverIp, String password) {
            ServerInfo serverInfo = null;
            try
            {
                Dao<ServerInfo, Integer> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(ServerInfo.class);

                serverInfo = dao.queryBuilder().where().eq(F_SERVER_IP, serverIp)
                        .and().eq(F_PASSWORD, password).queryForFirst();
                //list = dao.queryBuilder().orderBy(F_FILE_TYPE, false).query();
            }
            catch (SQLException e)
            {
                // TODO Auto-generated catch block
                serverInfo = null;
                e.printStackTrace();
            }
            return serverInfo;
        }

        public static List<ServerInfo> getServerList() {
            List<ServerInfo> list = null;
            try {
                Dao<ServerInfo, Integer> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(ServerInfo.class);
                list = dao.queryBuilder().orderBy(F_LAST_TIME, false).query();
            } catch (Exception e) {
                e.printStackTrace();
            }

            return list;
        }

        public static void remove(ServerInfo serverInfo) {
            try {
                Dao<ServerInfo, Integer> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(ServerInfo.class);
                dao.delete(serverInfo);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @DatabaseTable(tableName = "file_info_ex")
    public  static  class FileItemEx {
        public static final String F_FILE_PATH = "file_path"; //文件的路径
        public static final String F_OPEN_TIME = "open_time"; //上次打开的时间
        public static final String F_FILE_SIZE = "file_size"; //文件的大小
        public static final String F_WIDTH = "width"; //图片的宽度
        public static final String F_HEIGHT = "height"; //图片的高度
        public static final String F_PSD_COLOR_MODE = "psd_color_mode"; //psd文档的颜色模式

        @DatabaseField(columnName = F_FILE_PATH, id = true)
        public String filePath; //文件路径

        @DatabaseField(columnName = F_OPEN_TIME, defaultValue = "0")
        public long lastOpenTime; //上次打开时间

        @DatabaseField(columnName = F_FILE_SIZE)
        public long fileSize; //文件的大小

        @DatabaseField(columnName = F_WIDTH)
        public int width; //文件的宽度

        @DatabaseField(columnName = F_HEIGHT)
        public int height; //文件的高度

        @DatabaseField(columnName = F_PSD_COLOR_MODE)
        public int psdColorMode; //psd文档的颜色模式

        public boolean isSelected; //是否选中

        public void save(){
            try{
                Dao<FileItemEx, String> dao = KernelManager._GetObject()
                        .getDatabaseHelper().getDao(FileItemEx.class);
                lastOpenTime = System.currentTimeMillis();
                dao.createOrUpdate(this);
            }
            catch (Exception e){
                e.printStackTrace();
            }
        }

        @Override
        public String toString(){
            return  new StringBuilder("filePath:").append(filePath).append(", fileSize:")
                    .append(fileSize).append(", width:").append(width)
                    .append(", height:").append(height).append(", psdColorMode:")
                    .append(psdColorMode).toString();
        }

        public static List<FileItemEx> getFileList(){
            List<FileItemEx> list = null;
            try
            {
                Dao<FileItemEx, String> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(FileItemEx.class);

                //list = dao.queryForAll();
                list = dao.queryBuilder().orderBy(F_OPEN_TIME, false).query();
            }
            catch (SQLException e)
            {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }

            return list;
        }

        /**
         * 根据文件的路径获取文件信息
         * @param path
         * @return
         */
        public static FileItemEx getFileByPath(String path){
            FileItemEx fileItem = null;
            try
            {
                Dao<FileItemEx, String> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(FileItemEx.class);

                fileItem = dao.queryForId(path);
                //list = dao.queryBuilder().orderBy(F_FILE_TYPE, false).query();
            }
            catch (SQLException e)
            {
                // TODO Auto-generated catch block
                fileItem = null;
                e.printStackTrace();
            }
            return fileItem;
        }

        public static void delete(FileItemEx file){
            try {
                Dao<FileItemEx, String> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(FileItemEx.class);
                dao.delete(file);
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        /**
         * 查看指定路径的文件是否已存在数据库中
         * @param path
         * @return
         */
        public static boolean isFileIn(String path){
            boolean result = true;
            try{
                Dao<FileItemEx, String> dao = KernelManager._GetObject().getDatabaseHelper()
                        .getDao(FileItemEx.class);
                result = dao.idExists(path);
            }
            catch (Exception e){
                e.printStackTrace();
            }
            return result;
        }
    }

    /**
     * photoshop 消息体
     */
    public static class PhotoshopMessage
    {
        public int msgLen; //消息的长度, 未加密
        public int msgStatus; //消息的状态, 未加密
        public int protocolVersion; //协议的版本,必须为1; 0 = msgStatus 时该字段为加密字段, 否则未加密
        public int transactionId; //传输id, 0 = msgStatus 时该字段为加密字段, 否则未加密
        public int contentType; //内容的类型, 0 = msgStatus 时该字段为加密字段, 否则未加密
        public byte[] body; //消息体, 0 = msgStatus 时该字段为加密字段, 否则未加密
    }

}
