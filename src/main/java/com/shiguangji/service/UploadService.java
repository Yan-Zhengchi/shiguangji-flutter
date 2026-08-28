package com.shiguangji.service;

import com.shiguangji.common.BizException;
import com.shiguangji.common.ErrorCode;
import net.coobird.thumbnailator.Thumbnails;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import javax.imageio.ImageIO;

/**
 * 图片上传：OSS 未配置时的本地落盘方案（目录挂载宿主机数据卷）。
 * 写盘前对超过 500KB 的 jpg/png 做兜底压缩（与前端 ImageCompressor 同策略），
 * gif 动图与压缩失败的图原样保留，不影响上传。
 */
@Service
public class UploadService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp", "gif");
    private static final long MAX_SIZE = 10 * 1024 * 1024L;
    /** 兜底压缩目标：>500KB 的图压到达标以内 */
    private static final int TARGET_BYTES = 500 * 1024;

    private final Path uploadDir;

    public UploadService(@Value("${shiguangji.upload.dir:./uploads}") String dir) {
        this.uploadDir = Paths.get(dir).toAbsolutePath().normalize();
    }

    /** 返回可直接访问的相对 URL：/uploads/xxx.png */
    public String store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BizException(ErrorCode.PARAM_INVALID, "上传文件不能为空");
        }
        if (file.getSize() > MAX_SIZE) {
            throw new BizException(ErrorCode.PARAM_INVALID, "上传文件过大（限 10MB）");
        }
        String extension = resolveExtension(file.getOriginalFilename());
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new BizException(ErrorCode.PARAM_INVALID, "仅支持 jpg/png/webp/gif 图片");
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.toLowerCase(Locale.ROOT).startsWith("image/")) {
            throw new BizException(ErrorCode.PARAM_INVALID, "文件类型不是图片");
        }
        try {
            Files.createDirectories(uploadDir);
            String filename = UUID.randomUUID().toString().replace("-", "") + "." + extension;
            Path target = uploadDir.resolve(filename).normalize();
            if (!target.startsWith(uploadDir)) {
                throw new BizException(ErrorCode.PARAM_INVALID, "非法文件名");
            }
            byte[] data = file.getBytes();
            // 兜底压缩：>500KB 的非 gif 图压到达标；失败/不支持则原样落盘
            if (data.length > TARGET_BYTES && !"gif".equals(extension)) {
                try {
                    data = compressToTarget(data);
                } catch (Exception e) {
                    // webp 等无法解码的格式压缩失败时保留原图，不阻断上传
                }
            }
            Files.copy(new ByteArrayInputStream(data), target, StandardCopyOption.REPLACE_EXISTING);
            return "/uploads/" + filename;
        } catch (IOException e) {
            throw new BizException(ErrorCode.SYSTEM_ERROR, "文件保存失败");
        }
    }

    /** 质量步降压缩到 ≤500KB：1200px/JPEG 0.8 → 质量递减至 0.5 → 1080px/0.5 收底 */
    private byte[] compressToTarget(byte[] src) throws IOException {
        BufferedImage img = ImageIO.read(new ByteArrayInputStream(src));
        if (img == null) {
            throw new IOException("无法解码图片");
        }
        // JPEG 不支持透明通道：垫白底转 RGB，避免带 alpha 的 PNG 压缩失败/发黑
        BufferedImage rgb = new BufferedImage(img.getWidth(), img.getHeight(), BufferedImage.TYPE_INT_RGB);
        Graphics2D g = rgb.createGraphics();
        g.drawImage(img, 0, 0, Color.WHITE, null);
        g.dispose();
        int longest = Math.max(rgb.getWidth(), rgb.getHeight());
        if (longest > 1200) {
            rgb = Thumbnails.of(rgb).scale(1200.0 / longest).asBufferedImage();
        }
        for (float q = 0.8f; q >= 0.5f; q -= 0.1f) {
            byte[] out = jpeg(rgb, q);
            if (out.length <= TARGET_BYTES) {
                return out;
            }
        }
        double f = 1080.0 / Math.max(rgb.getWidth(), rgb.getHeight());
        if (f < 1.0) {
            // 已小于 1080 就不再缩（防止放大），仅以最低质量重编码
            rgb = Thumbnails.of(rgb).scale(f).asBufferedImage();
        }
        return jpeg(rgb, 0.5f);
    }

    private byte[] jpeg(BufferedImage img, float quality) throws IOException {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        Thumbnails.of(img).scale(1.0).outputQuality(quality).outputFormat("jpeg").toOutputStream(bos);
        return bos.toByteArray();
    }

    private String resolveExtension(String originalFilename) {
        if (originalFilename == null) {
            return "";
        }
        int dot = originalFilename.lastIndexOf('.');
        if (dot < 0 || dot == originalFilename.length() - 1) {
            return "";
        }
        return originalFilename.substring(dot + 1).toLowerCase(Locale.ROOT);
    }
}
